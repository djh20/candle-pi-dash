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
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock/wakelock.dart';

FlutterBluetoothSerial bluetoothSerial = FlutterBluetoothSerial.instance;

class Vehicle {
  late AppModel model;

  late List<TopicGroup> groups;
  var metrics = <String, Metric>{};

  bool connected = false;
  bool connecting = false;
  bool initialized = false;

  late PerformanceTracking pTracking;

  //Street? street;
  int? speedLimit;
  int? displayedSpeedLimit;
  int displayedSpeedLimitAge = 0;

  LatLng position = LatLng(0, 0);
  double bearingRad = 0;
  double bearingDeg = 0;
  
  String? btAddress;
  BluetoothConnection? btConnection;

  String buffer = "";
  bool _waitingForResponse = false;
  List<String>? _possibleResponses;
  Completer<String?>? _responseCompleter;
  Timer? _responseTimer;
  String? _lastCommand;
  
  TopicGroup? currentGroup;
  int? currentGroupIndex;
  Timer? groupTimer;

  bool recording = false;
  int? recordingStartMs;
  String recordedData = "";

  Vehicle(this.model) {
    pTracking = PerformanceTracking(this, [20, 40, 60, 80, 100]);

    groups = [
      TopicGroup(
        name: "High Priority",
        mask: 0x048, 
        filter: 0x000,
        duration: const Duration(milliseconds: 200),
        topics: [
          Topic(
            id: 0x421,
            name: "Shifter",
            bytes: 3
          ),
          Topic(
            id: 0x180,
            name: "Motor & Throttle",
            bytes: 8
          ),
          Topic(
            id: 0x284,
            name: "Speed",
            bytes: 8
          ),
          Topic(
            id: 0x5B3,
            name: "Battery",
            bytes: 8
          )
        ] 
      ),
      TopicGroup(
        name: "Low Priority",
        mask: 0x431, 
        filter: 0x401,
        duration: const Duration(milliseconds: 70),
        topics: [
          Topic(
            id: 0x54B,
            name: "Climate Control",
            bytes: 8
          ),
          Topic(
            id: 0x60D,
            name: "Doors & Indicators",
            bytes: 8
          ),
          Topic(
            id: 0x5C5,
            name: "Parking Brake & Odometer",
            bytes: 8
          )
        ] 
      )
    ];
    
    registerMetrics([
      Metric(
        id: "powered", 
        defaultValue: false, 
        timeout: const Duration(milliseconds: 1000)
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
      Metric(id: "fan_speed"),
      Metric(id: "driver_door_open", defaultValue: false),
      Metric(id: "passenger_door_open", defaultValue: false),
      Metric(id: "indicating_left", defaultValue: false),
      Metric(id: "indicating_right", defaultValue: false),
      Metric(id: "locked", defaultValue: false),
      Metric(id: "parking_brake_engaged", defaultValue: false),
      Metric(id: "odometer")
    ]);
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
        model.drawerOpen = false;
        model.hPageController.animateToPage(
          0, 
          duration: const Duration(milliseconds: 500), 
          curve: Curves.easeInOutQuad
        );

        // Allow all alerts to be shown again (for next trip).
        model.shownAlerts.clear();
        model.alertsEnabled = false;

        // So we will start on the map page next time the drawer is opened.
        model.vPage = 0;

        // Clear any cached data.
        rootBundle.clear();
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
      
    } else if (metric.id == 'fan_speed' && metric.value > 0) {
      model.showAlert("cc_on");
    
    } else if (metric.id == 'gids' || metric.id == 'soh') {
      final int gids = metrics['gids']!.value;
      final int soh = metrics['soh']!.value;

      final double energyKwh = max((gids*Constants.kwhPerGid), 0);
      
      // Range Calculation
      // - Minus 1.15kWh is reserved energy that cannot be used.
      final int range = ((energyKwh-1.15)*Constants.kmPerKwh).round();
      metrics['range']?.setValue(range);

      final double batteryCapacity = ((soh/100.0)*Constants.fullBatteryCapacity);
      final double soc = (energyKwh/batteryCapacity)*100;
      metrics['soc']?.setValue(soc);

    } else if (metric.id == 'range') {
      int range = metric.value;
      if (range > 0 && range <= 10) model.showAlert("low_range");

    } else if (metric.id == 'gps_lat' || metric.id == 'gps_lng') {
      double lat = metrics["gps_lat"]?.value;
      double lng = metrics["gps_lng"]?.value;

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
        buffer += String.fromCharCode(charCode);

      } else if (buffer.isNotEmpty) {
        String msg = buffer.replaceAll('>', '');
        model.log("RX: $msg");

        if (msg == "BUFFER FULL") {
          monitorAll();
          
        } else {
          if (recording) {
            int ms = millis() - recordingStartMs!;
            recordedData += '$ms\t$msg\n';
          }

          processFrame(msg);
        }

        if (_waitingForResponse && _possibleResponses!.contains(msg)) {
          _waitingForResponse = false;
          _responseTimer?.cancel();
          _responseCompleter?.complete(buffer);
        }

        buffer = "";
      }
    }
  }

  void processFrame(String frame) {
    for (var group in groups) {
      for (var topic in group.topics) {
        if (frame.startsWith(topic.idHex)) {
          String frameDataStr = frame.substring(topic.idHex.length);
          if (frameDataStr.length == topic.bytes * 2) {
            RegExp exp = RegExp(r'.{2}');
            Iterable<Match> matches = exp.allMatches(frameDataStr);
            var frameData = 
              matches.map((m) => int.tryParse(m.group(0) ?? '', radix: 16) ?? 0).toList();
            
            processTopicData(topic, frameData);
            //model.log(topic.name);
            //model.log(group.name);
          }
          return;
        }
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
      metrics['powered']?.setValue(true);

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
      metrics['indicating_left']?.setValue((data[2] & 0x40) > 0);
      metrics['indicating_right']?.setValue((data[2] & 0x20) > 0);
      metrics['locked']?.setValue((data[2] & 0x08) > 0);

    } else if (topic.id == 0x5C5) {
      metrics['parking_brake_engaged']?.setValue((data[0] & 0x04) > 0);
      metrics['odometer']?.setValue((data[1] << 16) | (data[2] << 8) | data[3]);
    }
  }

  Future<String?> sendCommand(
    String command, 
    {
      bool waitForResponse = true,
      List<String>? possibleResponses,
      Duration? timeout
    }
  ) async {
    if (_waitingForResponse) await _responseCompleter!.future;
    model.log("TX: $command");

    command = command.replaceAll(' ', '');
    _lastCommand = command;
    
    btConnection?.output.add(ascii.encode('$command\r'));
    
    if (waitForResponse) {
      _responseCompleter = Completer<String?>();
      _possibleResponses = possibleResponses ?? [command];
      _waitingForResponse = true;

      if (timeout != null) {
        _responseTimer = Timer(timeout, () => _responseCompleter?.complete());
      }

      return _responseCompleter!.future;
    }
    
    //return Future.delayed(const Duration(milliseconds: 20), () => "");
    return null;
  }

  Future<void> monitorAll() async {
    if (!connected || currentGroup == null) return;

    await sendCommand("AT MA");
  }

  Future<void> nextGroup() async {
    if (!connected) return;

    if (currentGroup != null) {
      currentGroup = null;

      // Stop monitoring
      await sendCommand(
        'STOP', 
        possibleResponses: ['STOPPED', '?'],
        timeout: const Duration(milliseconds: 500)
      );
      //await Future.delayed(const Duration(milliseconds: 10));
    }
    
    currentGroupIndex ??= 0;
    currentGroupIndex = currentGroupIndex! + 1;

    if (currentGroupIndex! >= groups.length) {
      currentGroupIndex = 0;
    }

    TopicGroup group = groups[currentGroupIndex!];

    await sendCommand('AT CM ${group.maskHex}');
    await sendCommand('AT CF ${group.filterHex}');

    currentGroup = group;
    groupTimer = Timer(group.duration, nextGroup);

    monitorAll();
  }

  void connect() async {
    if (connected || connecting) return;

    if (btAddress == null && await bluetoothSerial.isAvailable == true) {
      var bondedDevices = await bluetoothSerial.getBondedDevices();
      if (bondedDevices.isNotEmpty) {
        btAddress = bondedDevices[0].address;
      }
    }

    if (btAddress != null) {
      connecting = true;
      model.log('Connecting to $btAddress');

      try {
        var connection = await BluetoothConnection.toAddress(btAddress);
        if (connection.isConnected) {
          connected = true;
          btConnection = connection;
          connection.input?.listen(processIncomingData);
        }

      } catch (exception) {
        debugPrint(exception.toString());
      }

      connecting = false;
    }

    if (btConnection != null && connected) {
      model.log('Connected!');
      
      Future.delayed(const Duration(milliseconds: 50), () async {
        model.log('Initializing...');
        await sendCommand("AT Z", waitForResponse: false);
        await Future.delayed(const Duration(seconds: 2));
        //await sendCommand("AT E0");
        await sendCommand("AT SP6");
        await sendCommand("AT CAF0");
        await sendCommand("AT S0");
        await sendCommand("AT H1");
        //await sendCommand("AT CF 000");
        //await sendCommand("AT CM 048");
        initialized = true;
        model.log("Initialized!");
        
        nextGroup();
      });

      model.notify('connected');
    } else {
      model.log('Connection failed!');
      Future.delayed(const Duration(milliseconds: 500), connect);
    }
  }

  void close() async {
    if (!connected) return;

    initialized = false;
    connected = false;
    model.notify('connected');

    await sendCommand("AT MA");
    await sendCommand("AT Z");

    btConnection?.close();
    btConnection?.dispose();
    btConnection = null;
    _responseCompleter = null;

    //commandQueue.clear();
    //metrics.clear();

    model.log('Disconnected!');
  }

  void reconnect() {
    if (connecting) return;

    close(); connect();
  }

  File getDataFile() => File('/storage/emulated/0/Download/data.txt');

  Future<void> startRecording() async {
    //if (!await Permission.manageExternalStorage.request().isGranted) return;

    recordedData = "";
    recordingStartMs = millis();
    recording = true;
    model.notify('recording');
  }

  Future<void> stopRecording() async {
    recording = false;
    model.notify('recording');

    final file = getDataFile();
    await file.writeAsString(recordedData);
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
