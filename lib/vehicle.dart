import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:candle_dash/can.dart';
import 'package:candle_dash/constants.dart';
import 'package:candle_dash/model.dart';
import 'package:candle_dash/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:latlong2/latlong.dart';
import 'package:collection/collection.dart';
import 'package:wakelock/wakelock.dart';
import 'package:geolocator/geolocator.dart';

FlutterBluetoothSerial bluetoothSerial = FlutterBluetoothSerial.instance;

class Vehicle {
  late AppModel model;

  late List<TopicGroup> groups;
  var metrics = <String, Metric>{};

  bool connected = false;
  bool connecting = false;

  late PerformanceTracking pTracking;

  //Street? street;
  int? speedLimit;
  int? displayedSpeedLimit;
  int displayedSpeedLimitAge = 0;

  LatLng position = LatLng(0, 0);
  double bearingRad = 0;
  double bearingDeg = 0;
  
  String? _btAddress;
  BluetoothConnection? _btConnection;

  String _buffer = "";

  final List<Command> _commandQueue = [];
  Command? _latestCommand;
  Timer? _commandTimer;
  
  TopicGroup? _currentGroup;
  int? _currentGroupIndex;
  Timer? _groupTimer;
  DateTime? _groupStartTime;
  final _timings = <String, int>{};
  List<Topic> _pendingTopics = [];

  bool recording = false;
  int? _recordingStartMs;
  String _recordedData = "";

  Vehicle(this.model) {
    pTracking = PerformanceTracking(this, [20, 40, 60, 80, 100]);

    groups = [
      TopicGroup(
        name: "High Speed",
        //mask: 0x048, 
        //filter: 0x000,
        timeout: const Duration(milliseconds: 500),
        topics: [
          Topic(
            id: 0x421,
            name: "Shifter",
            bytes: 3,
            isEnabled: () => metrics['speed']?.value < 10
            //shouldWait: () => true
          ),
          Topic(
            id: 0x180,
            name: "Motor & Throttle",
            bytes: 8,
            isEnabled: () => metrics['gear']?.value > 0
            //shouldWait: () => metrics['gear']?.value > 0
          ),
          Topic(
            id: 0x284,
            name: "Speed",
            bytes: 8,
            isEnabled: () => metrics['gear']?.value > 0
            //shouldWait: () => metrics['gear']?.value > 0
          ),
          Topic(
            id: 0x292,
            name: "Lead Acid Battery",
            bytes: 8,
            isEnabled: () => true
            //shouldWait: () => false
          ),
        ] 
      ),
      TopicGroup(
        name: "Low Speed #1",
        //mask: 0x431, 
        //filter: 0x401,
        timeout: const Duration(milliseconds: 100),
        topics: [
          Topic(
            id: 0x54B,
            name: "Climate Control",
            bytes: 8,
            isEnabled: () => true
            //shouldWait: () => true
          ),
          Topic(
            id: 0x60D,
            name: "Doors",
            bytes: 8,
            isEnabled: () => metrics['speed']?.value == 0,
            //shouldWait: () => metrics['gear']?.value == 0
          ),
          Topic(
            id: 0x5C5,
            name: "Parking Brake & Odometer",
            bytes: 8,
            isEnabled: () =>
              metrics['parking_brake_engaged']?.value == true || 
              metrics['speed']?.value == 0
            //shouldWait: () => metrics['gear']?.value == 0
          )
        ] 
      ),
      TopicGroup(
        name: "Low Speed #2",
        //mask: 0x114, 
        //filter: 0x110,
        timeout: const Duration(milliseconds: 100),
        topics: [
          Topic(
            id: 0x358,
            name: "Indicators & Headlights",
            bytes: 8,
            isEnabled: () => metrics['gear']?.value > 0
            //shouldWait: () => true
          ),
          Topic(
            id: 0x5B3,
            name: "HV Battery",
            bytes: 8,
            isEnabled: () => true,
            //important: false
            //shouldWait: () => false
          ),
        ] 
      )
    ];
    
    registerMetrics([
      Metric(
        id: "powered", 
        defaultValue: false, 
        timeout: const Duration(seconds: 2)
      ),
      Metric(id: "gear"),
      Metric(id: "eco", defaultValue: false),
      Metric(id: "speed", defaultValue: 0.0),
      Metric(id: "fl_speed", defaultValue: 0.0),
      Metric(id: "fr_speed", defaultValue: 0.0),
      Metric(id: "motor_power", defaultValue: 0.0),
      Metric(id: "soh"),
      Metric(id: "gids"),
      Metric(id: "soc", defaultValue: 0.0),
      Metric(id: "range"),
      Metric(id: "fan_speed", timeout: const Duration(seconds: 2)),
      Metric(id: "driver_door_open", defaultValue: false),
      Metric(id: "passenger_door_open", defaultValue: false),
      Metric(
        id: "left_turn_signal", 
        defaultValue: false, 
        //timeout: const Duration(seconds: 1)
      ),
      Metric(
        id: "right_turn_signal", 
        defaultValue: false, 
        //timeout: const Duration(seconds: 1)
      ),
      Metric(id: "locked", defaultValue: false),
      Metric(id: "parking_brake_engaged", defaultValue: false),
      Metric(id: "odometer"),
      Metric(id: "lead_acid_voltage"),
      Metric(id: "gps_lock", defaultValue: false),
    ]);

    _initGps();
  }

  void registerMetrics(List<Metric> metrics) {
    for (var metric in metrics) {
      metric.onUpdate = metricUpdated;
      this.metrics[metric.id] = metric;
      model.log('Registered metric: ${metric.id}');
    }
  }

  void metricUpdated(Metric metric) {
    if (metric.id == 'powered') {
      if (metric.value == true) {
        Wakelock.enable();
        model.alertsEnabled = true;
        model.showAlert("experimental");

      } else {
        Wakelock.disable();
        pTracking.setTracking(false);
        
        // Close drawer
        /*
        model.drawerOpen = false;
        model.hPageController.animateToPage(
          0, 
          duration: const Duration(milliseconds: 500), 
          curve: Curves.easeInOutQuad
        );
        */

        // Allow all alerts to be shown again (for next trip).
        model.shownAlerts.clear();
        model.alertsEnabled = false;

        // So we will start on the map page next time the drawer is opened.
        //model.vPage = 0;

        // Clear any cached data.
        //rootBundle.clear();
      }

    } else if (metric.id == 'speed') {
      final double speed = metric.value;
      pTracking.update(speed);

      final bool speeding = 
        speedLimit != null && 
        speed > (speedLimit! + Constants.speedingAlertThreshold);

      if (speeding && model.speedingAlertsEnabled) {
        final int now = millis();

        if (model.speedingStartTime != null) {
          final int timeSinceStartedSpeeding = now - model.speedingStartTime!;

          if (timeSinceStartedSpeeding >= Constants.speedingAlertTime) {
            model.showAlert("speeding");
            model.speedingStartTime = null;
          }

        } else {
          model.speedingStartTime = now;
        }
      } else {
        model.speedingStartTime = null;
      }
    
    /*
    } else if (metric.id == 'fan_speed' && metric.value > 0) {
      model.showAlert("cc_on");
    */
    
    } else if (metric.id == 'gids' || metric.id == 'soh') {
      final int gids = metrics['gids']!.value;
      final int soh = metrics['soh']!.value;

      final double energyKwh = (gids*Constants.kwhPerGid);
      
      // Range Calculation
      // - Minus ~1kWh is reserved energy that cannot be used.
      final int range = max(((energyKwh-1)*Constants.kmPerKwh).round(), 0);
      metrics['range']?.setValue(range);

      final double batteryCapacity = ((soh/100.0)*Constants.fullBatteryCapacity);
      final double soc = (energyKwh/batteryCapacity)*100;
      metrics['soc']?.setValue(soc);

    } else if (metric.id == 'range') {
      int range = metric.value;
      if (range > 0 && range <= 10) model.showAlert("low_range");

    } else if (metric.id == 'gps_lock' && metric.value == 0) {
      speedLimit = null;
      displayedSpeedLimitAge = 999999;
      model.notify("speedLimit");
    }
    
    model.notify(metric.id);
  }

  void processIncomingData(Uint8List data) {
    for (var charCode in data) {
      if (charCode != 13) {
        _buffer += String.fromCharCode(charCode);

      } else if (_buffer.isNotEmpty) {
        String msg = _buffer.replaceAll('>', '');
        model.log("RX: $msg");

        if (msg == "BUFFER FULL") {
          if (_currentGroup != null) {
            _sendCommand(Command("AT MA"));
          }
          
        } else {
          if (recording) {
            int ms = millis() - _recordingStartMs!;
            _recordedData += '$ms\t$msg\n';
          }

          processFrame(msg);
        }

        final bool waitingForResponse = _latestCommand?.completer.isCompleted == false;
        if (waitingForResponse && _latestCommand!.validResponses.contains(msg)) {
          _commandTimer?.cancel();
          _completeCommand(_latestCommand!, msg);
        }

        _buffer = "";
      }
    }
  }

  void processFrame(String frame) {
    for (var group in groups) {
      final Topic? frameTopic = 
        group.topics.firstWhereOrNull((topic) => frame.startsWith(topic.idHex));

      if (frameTopic != null) {
        String frameDataStr = frame.substring(frameTopic.idHex.length);

        if (frameDataStr.length == frameTopic.bytes * 2) {
          model.log(frameTopic.name, category: 1);

          final RegExp exp = RegExp(r'.{2}');
          final Iterable<Match> matches = exp.allMatches(frameDataStr);
          final frameData = 
            matches.map((m) => int.tryParse(m.group(0) ?? '', radix: 16) ?? 0).toList();
          
          processTopicData(frameTopic, frameData);

          if (_currentGroup != null && _pendingTopics.remove(frameTopic)) {
            model.log(_pendingTopics.map((t) => t.name).toList().toString(), category: 2);
            if (_pendingTopics.isEmpty) nextGroup();
          }
        } else {
          model.log('${frameTopic.name} (INVALID)', category: 1);
        }
        break;
      }
    }
  }

  void processTopicData(Topic topic, List<int> data) {
    if (topic.id == 0x421) {
      bool eco = false;
      int gear = 0;

      switch (data[0]) {
        case 8: // Park
          gear = 0;
          break;

        case 16: // Reverse
          gear = 1;
          break;
        
        case 24: // Neutral
          gear = 2;
          break;

        case 32: // Drive
          gear = 3;
          break;

        case 56: // Eco
          gear = 3;
          eco = true;
          break;
      }

      metrics['gear']?.setValue(gear);
      metrics['eco']?.setValue(eco);

    } else if (topic.id == 0x180) {
      int rawPower = (data[2] << 8) | data[3];
      if ((rawPower & 0x8000) > 0) {
        rawPower = -(~rawPower & 0xFFFF);
      }

      // TODO: Make this more accurate.
      double power = rawPower / 200;
      metrics['motor_power']?.setValue(power);

    } else if (topic.id == 0x284) {
      double frontRightSpeed = ((data[0] << 8) | data[1]) / 208;
      double frontLeftSpeed = ((data[2] << 8) | data[3]) / 208;

      double speed = (frontRightSpeed + frontLeftSpeed) / 2;
      
      metrics['speed']?.setValue(speed);
      metrics['fl_speed']?.setValue(frontLeftSpeed);
      metrics['fr_speed']?.setValue(frontRightSpeed);

    } else if (topic.id == 0x5B3) {
      final int gids = data[5];

      // Gids shows as high value on startup - this is incorrect, so we ignore it.
      if (gids < 1000) metrics['gids']?.setValue(gids);
      
      metrics['soh']?.setValue(data[1] >> 1);

    } else if (topic.id == 0x54B) {
      metrics['fan_speed']?.setValue(data[4] >> 3);

    } else if (topic.id == 0x60D) {
      metrics['driver_door_open']?.setValue((data[0] & 0x10) > 0);
      metrics['passenger_door_open']?.setValue((data[0] & 0x08) > 0);

      //metrics['powered']?.setValue(((data[1] >> 1) & 0x03) == 3);
      //metrics['indicating_left']?.setValue((data[2] & 0x40) > 0);
      //metrics['indicating_right']?.setValue((data[2] & 0x20) > 0);

      /*
      if ((data[1] & 0x20) > 0) {
        metrics['indicating_left']?.setValue(true);
      }

      if ((data[1] & 0x40) > 0) {
        metrics['indicating_right']?.setValue(true);
      }
      */

      metrics['locked']?.setValue((data[2] & 0x08) > 0);

    } else if (topic.id == 0x5C5) {
      metrics['parking_brake_engaged']?.setValue((data[0] & 0x04) > 0);
      metrics['odometer']?.setValue((data[1] << 16) | (data[2] << 8) | data[3]);

    } else if (topic.id == 0x358) {
      metrics['left_turn_signal']?.setValue((data[2] & 0x02) > 0);
      metrics['right_turn_signal']?.setValue((data[2] & 0x04) > 0);

    } else if (topic.id == 0x292) {
      metrics['lead_acid_voltage']?.setValue(data[3] / 10);
      metrics['powered']?.setValue(true);
    }
  }

  Future<String?> _sendCommand(Command command) {
    _commandQueue.add(command);
    if (_commandQueue.length == 1) _processCommandQueue();

    return command.completer.future;
  }

  void _processCommandQueue() {
    if (!connected || _commandQueue.isEmpty) return;
    if (_latestCommand?.completer.isCompleted == false) return;

    final command = _commandQueue.first;
    _commandQueue.remove(command);
    _latestCommand = command;
    
    model.log('TX: ${command.text}');
    _btConnection?.output.add(ascii.encode('${command.text}\r'));

    _commandTimer = Timer(command.timeout, () => _completeCommand(command, null));
  }

  void _completeCommand(Command command, String? response) {
    command.completer.complete(response);
    _processCommandQueue();
  }

  Future<void> nextGroup() async {
    if (!connected) return;

    if (_currentGroup != null) {
      String groupName = _currentGroup!.name;
      _currentGroup = null;
      _groupTimer?.cancel();

      DateTime before = DateTime.now();
      // Stop monitoring
      await _sendCommand(Command('STOP', validResponses: ['STOPPED', '?']));
      _timings['stop'] = DateTime.now().difference(before).inMilliseconds;

      //await Future.delayed(const Duration(milliseconds: 10));
      _timings['total'] = DateTime.now().difference(_groupStartTime!).inMilliseconds;

      model.log('$groupName: ${_timings['total']} (${_timings['init']}, ${_timings['stop']})', category: 2);
    }

    _timings.clear();
    
    _groupStartTime = DateTime.now();
    _currentGroupIndex ??= 0;
    _currentGroupIndex = _currentGroupIndex! + 1;

    if (_currentGroupIndex! >= groups.length) {
      _currentGroupIndex = 0;
    }

    TopicGroup group = groups[_currentGroupIndex!];
    
    List<Topic> enabledTopics = group.topics.where((topic) => topic.isEnabled()).toList();
    List<int> ids = enabledTopics.map((topic) => topic.id).toList();

    int filter = ids[0];
    for (int i = 1; i < ids.length; i++) {
      filter = filter & ids[i];
    }
    
    int mask = ~ids[0];
    for (int i = 1; i < ids.length; i++) {
      mask = mask & ~ids[i];
    }
    mask = (mask | filter) & 0x7FF;

    String filterHex = intToHex(filter, 3);
    String maskHex = intToHex(mask, 3);

    DateTime before = DateTime.now();
    await _sendCommand(Command('AT CM $maskHex'));
    await _sendCommand(Command('AT CF $filterHex'));

    _pendingTopics = enabledTopics;
    //_pendingTopics = enabledTopics.where((topic) => topic.important).toList();
    model.log(_pendingTopics.map((t) => t.name).toList().toString(), category: 2);
    
    await _sendCommand(Command("AT MA"));
    _currentGroup = group;
    _groupTimer = Timer(group.timeout, nextGroup);
    _timings['init'] = DateTime.now().difference(before).inMilliseconds;
  }

  void connect() async {
    if (connected || connecting) return;

    if (_btAddress == null && await bluetoothSerial.isAvailable == true) {
      var bondedDevices = await bluetoothSerial.getBondedDevices();
      if (bondedDevices.isNotEmpty) {
        _btAddress = bondedDevices[0].address;
      }
    }

    if (_btAddress != null) {
      connecting = true;
      model.log('Connecting to $_btAddress');
      
      //final pos = await _determinePosition();
      //model.log('${pos.latitude}, ${pos.longitude}');

      try {
        var connection = await BluetoothConnection.toAddress(_btAddress);
        if (connection.isConnected) {
          connected = true;
          _btConnection = connection;
          connection.input?.listen(processIncomingData);
        }

      } catch (exception) {
        debugPrint(exception.toString());
      }

      connecting = false;
    }

    if (_btConnection != null && connected) {
      model.log('Connected!');
      
      Future.delayed(const Duration(milliseconds: 50), () async {
        model.log('Initializing...');
        await _sendCommand(Command("AT Z"));
        await Future.delayed(const Duration(seconds: 2));
        //await sendCommand("AT E0");
        await _sendCommand(Command("AT SP6"));
        await _sendCommand(Command("AT CAF0"));
        await _sendCommand(Command("AT S0"));
        await _sendCommand(Command("AT H1"));
        //await _sendCommand(Command("AT CF 000"));
        //await sendCommand("AT CM 048");
        model.log("Initialized!");
        
        nextGroup();
      });

      model.notify('connected');
    } else {
      model.log('Connection failed!');
      Future.delayed(const Duration(milliseconds: 500), connect);
    }
  }

  void disconnect() async {
    if (!connected) return;

    _currentGroup = null;
    _commandTimer?.cancel();
    _groupTimer?.cancel();

    _sendCommand(Command("STOP", validResponses: ['STOPPED', '?']));
    await _sendCommand(Command("AT Z"));

    _btConnection?.close();
    _btConnection?.dispose();
    _btConnection = null;
    
    connected = false;
    model.notify('connected');

    //commandQueue.clear();
    //metrics.clear();

    model.log('Disconnected!');
  }

  void reconnect() {
    if (connecting) return;

    disconnect(); connect();
  }

  File getDataFile() => File('/storage/emulated/0/Download/data.txt');

  Future<void> startRecording() async {
    //if (!await Permission.manageExternalStorage.request().isGranted) return;

    _recordedData = "";
    _recordingStartMs = millis();
    recording = true;
    model.notify('recording');
  }

  Future<void> stopRecording() async {
    recording = false;
    model.notify('recording');

    final file = getDataFile();
    await file.writeAsString(_recordedData);
    model.log('Saved data to ${file.path}');
  }

  Future<void> playbackData() async {
    //if (!await Permission.manageExternalStorage.request().isGranted) return;
    
    if (!connected) {
      connected = true;
      model.notify('connected');
    }

    int startMs = millis();

    final file = getDataFile();
    Stream<String> lines = file.openRead()
      .transform(utf8.decoder)       // Decode bytes to UTF-8.
      .transform(const LineSplitter());    // Convert stream to individual lines.

    await for (var line in lines) {
      //print('$line: ${line.length} characters');
      List<String> sections = line.trim().split('\t');
      int ms = int.parse(sections[0]);
      String frame = sections[1];

      var msUntilFrame = ms - (millis() - startMs);

      if (msUntilFrame > 0) {
        await Future.delayed(Duration(milliseconds: msUntilFrame));
      }

      processFrame(frame);
    }
  }

  /// Determine the current position of the device.
  ///
  /// When the location services are not enabled or permissions
  /// are denied the `Future` will return an error.
  Future<void> _initGps() async {
    model.log('Initializing GPS...', category: 3);
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the 
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale 
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately. 
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.');
    }

    model.log('Listening to position stream...', category: 3);

    final LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high
    );

    Geolocator.getPositionStream(locationSettings: locationSettings).listen(
    (Position? position) {
        /*
        model.log(
          position == null ? 'Unknown' : '${position.latitude.toString()}, ${position.longitude.toString()}',
          category: 3
        );
        */
        metrics['gps_lock']?.setValue(position != null);
        if (position == null) return;

        _updatePosition(position.latitude, position.longitude);
    });
  }

  void _updatePosition(double lat, double lng) {
    const distance = Distance();
    final oldPos = position;
    final newPos = LatLng(lat, lng);
    
    final double distanceM = distance.as(
      LengthUnit.Meter,
      oldPos,
      newPos
    );

    /// Update the map only if the vehicle has moved at least 5m.
    /// This stops the map from moving and rotating when the vehicle is not
    /// moving.
    if (distanceM >= 5) {
      Bearing bearing = getBearingBetweenPoints(oldPos, newPos);
      bearingRad = bearing.radians;
      bearingDeg = bearing.degrees;

      debugPrint("$oldPos -> $newPos = $bearingDeg");
      model.updateMap(newPos, bearingDeg);
    }

    position = newPos;
  }

  int millis() => DateTime.now().millisecondsSinceEpoch;
}

class PerformanceTracking {
  final Vehicle vehicle;

  bool tracking = false;
  bool waiting = false;
  bool accelerating = false;

  int startTime = 0;

  double speed = 0;

  final List<double> milestoneSpeeds;
  List<PerformanceMilestone> milestones = [];

  PerformanceTracking(this.vehicle, this.milestoneSpeeds) {
    reset();
  }

  void setTracking(bool value) {
    tracking = value;
    accelerating = false;
    waiting = false;

    if (tracking) {
      // This makes it so you can turn on tracking when not moving.
      update(speed);
    }
    
    vehicle.model.notify("pTracking");
  }

  int getMs() {
    return DateTime.now().millisecondsSinceEpoch;
  }

  void reset() {
    milestones.clear();

    for (var speed in milestoneSpeeds) {
      milestones.add(PerformanceMilestone(speed: speed.round()));
    }
    
    vehicle.model.notify("pTracking");
  }

  void update(double speed) {
    if (tracking) {
      if (speed == 0 && !waiting) {
        waiting = true;
        reset();

      } else if (waiting && speed > 0) {
        startTime = getMs();
        waiting = false;
        accelerating = true;
      }
      
      if (accelerating) {
        for (var i = 0; i < milestones.length; i++) {
          final milestone = milestones[i];
          if (!milestone.reached) {
            if (speed >= milestone.speed) {
              double time = (getMs() - startTime) / 1000;
              milestone.reached = true;
              milestone.time = time;

              vehicle.model.audioPlayer.play('${milestone.speed}.mp3');

              vehicle.model.notify("pTracking");
            }
          }
        }
      }
    }
    this.speed = speed;
  }
}

class PerformanceMilestone {
  final int speed;

  bool reached;
  double time;

  PerformanceMilestone({
    required this.speed,
    this.reached = false,
    this.time = 0
  });
}
