import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:candle_dash/can.dart';
import 'package:candle_dash/constants.dart';
import 'package:candle_dash/elm.dart';
import 'package:candle_dash/model.dart';
import 'package:candle_dash/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:tcp_socket_connection/tcp_socket_connection.dart';
import 'package:collection/collection.dart';
import 'package:latlong2/latlong.dart';
import 'package:wakelock/wakelock.dart';
import 'package:geolocator/geolocator.dart';

FlutterBluetoothSerial bluetoothSerial = FlutterBluetoothSerial.instance;

class Vehicle {
  late AppModel model;

  final Map<String, Metric> metrics = {};
  final Map<int, CanTopic> _topics = {};
  final List<ElmTask> _tasks = [];

  bool connected = false;
  bool connecting = false;

  late PerformanceTracking pTracking;

  //Street? street;
  int? speedLimit;
  int? displayedSpeedLimit;
  int displayedSpeedLimitAge = 0;

  LatLng? position;
  double bearingRad = 0;
  double bearingDeg = 0;
  
  String? _btAddress;
  BluetoothConnection? _btConnection;
  TcpSocketConnection? _socketConnection;

  String _buffer = "";

  final List<ElmCommand> _pendingCommands = [];
  //ElmCommand? _latestCommand;
  //Timer? _commandTimer;
  
  //ElmTask? _currentTask;
  final List<ElmTask> _taskQueue = [];

  bool recording = false;
  int? _recordingStartMs;
  String _recordedData = "";

  late StreamSubscription<Position> _positionSubscription;

  Vehicle(this.model) {
    pTracking = PerformanceTracking(this, [20, 40, 60, 80, 100]);

    registerTopics([
      CanTopic(
        id: 0x002,
        name: "Steering",
        bytes: 5,
        interval: const Duration(milliseconds: 10)
      ),
      CanTopic(
        id: 0x02A,
        name: "Unknown",
        bytes: 3,
        interval: const Duration(milliseconds: 100)
      ),
      CanTopic(
        id: 0x130,
        name: "Unknown",
        bytes: 3,
        interval: const Duration(milliseconds: 10)
      ),
      CanTopic(
        id: 0x174,
        name: "VCM",
        bytes: 8,
        interval: const Duration(milliseconds: 10)
      ),
      CanTopic(
        id: 0x176,
        name: "Motor Voltage",
        bytes: 7,
        interval: const Duration(milliseconds: 10)
      ),
      CanTopic(
        id: 0x180,
        name: "Motor Current & Throttle",
        bytes: 8,
        interval: const Duration(milliseconds: 10)
      ),
      CanTopic(
        id: 0x1CA,
        name: "Brake Pressure",
        bytes: 8,
        interval: const Duration(milliseconds: 10)
      ),
      CanTopic(
        id: 0x1CB,
        name: "Target Regen Braking",
        bytes: 7,
        interval: const Duration(milliseconds: 10)
      ),
      CanTopic(
        id: 0x1D5,
        name: "Applied Regen Braking",
        bytes: 5,
        interval: const Duration(milliseconds: 10)
      ),
      CanTopic(
        id: 0x1F9,
        name: "Unknown",
        bytes: 8,
        interval: const Duration(milliseconds: 10)
      ),
      CanTopic(
        id: 0x215,
        name: "Unknown",
        bytes: 6,
        interval: const Duration(milliseconds: 20)
      ),
      CanTopic(
        id: 0x216,
        name: "Unknown",
        bytes: 2,
        interval: const Duration(milliseconds: 20)
      ),
      CanTopic(
        id: 0x245,
        name: "Unknown",
        bytes: 8,
        interval: const Duration(milliseconds: 20)
      ),
      CanTopic(
        id: 0x260,
        name: "Cluster Power Values",
        bytes: 4,
        interval: const Duration(milliseconds: 20)
      ),
      CanTopic(
        id: 0x280,
        name: "Cluster Speed",
        bytes: 8,
        interval: const Duration(milliseconds: 20)
      ),
      CanTopic(
        id: 0x284,
        name: "Front Wheel Speeds",
        bytes: 8,
        interval: const Duration(milliseconds: 20)
      ),
      CanTopic(
        id: 0x285,
        name: "Rear Wheel Speeds",
        bytes: 8,
        interval: const Duration(milliseconds: 20)
      ),
      CanTopic(
        id: 0x292,
        name: "12V Battery",
        bytes: 8,
        interval: const Duration(milliseconds: 20)
      ),
      CanTopic(
        id: 0x2DE,
        name: "Unknown",
        bytes: 8,
        interval: const Duration(milliseconds: 10)
      ),
      CanTopic(
        id: 0x300,
        name: "Steering Force",
        bytes: 1,
        interval: const Duration(milliseconds: 20)
      ),
      CanTopic(
        id: 0x351,
        name: "Unknown",
        bytes: 8,
        interval: const Duration(milliseconds: 100)
      ),
      CanTopic(
        id: 0x354,
        name: "Vehicle Speed (ABS)",
        bytes: 8,
        interval: const Duration(milliseconds: 40)
      ),
      CanTopic(
        id: 0x355,
        name: "Cluster Speed & Units",
        bytes: 7,
        interval: const Duration(milliseconds: 40)
      ),
      CanTopic(
        id: 0x358,
        name: "Indicators & Headlights",
        bytes: 8,
        interval: const Duration(milliseconds: 100)
      ),
      CanTopic(
        id: 0x35D,
        name: "Unknown",
        bytes: 8,
        interval: const Duration(milliseconds: 100)
      ),
      CanTopic(
        id: 0x385,
        name: "Tire Pressure",
        bytes: 8,
        interval: const Duration(milliseconds: 100)
      ),
      CanTopic(
        id: 0x421,
        name: "Dash Shifter Position",
        bytes: 3,
        interval: const Duration(milliseconds: 60)
      ),
      CanTopic(
        id: 0x50A,
        name: "Unknown",
        bytes: 8,
        interval: const Duration(milliseconds: 100)
      ),
      CanTopic(
        id: 0x50D,
        name: "Unknown",
        bytes: 8,
        interval: const Duration(milliseconds: 100)
      ),
      CanTopic(
        id: 0x510,
        name: "Climate Control #1",
        bytes: 8,
        interval: const Duration(milliseconds: 100)
      ),
      CanTopic(
        id: 0x54A,
        name: "Climate Control #2",
        bytes: 8,
        interval: const Duration(milliseconds: 100)
      ),
      CanTopic(
        id: 0x54B,
        name: "Climate Control #3",
        bytes: 8,
        interval: const Duration(milliseconds: 100)
      ),
      CanTopic(
        id: 0x551,
        name: "Unknown",
        bytes: 8,
        interval: const Duration(milliseconds: 100)
      ),
      CanTopic(
        id: 0x5A9,
        name: "Cluster Range",
        bytes: 8,
        interval: const Duration(milliseconds: 500)
      ),
      CanTopic(
        id: 0x5B3,
        name: "HV Battery",
        bytes: 8,
        interval: const Duration(milliseconds: 500)
      ),
      CanTopic(
        id: 0x5C0,
        name: "Battery Stats",
        bytes: 8,
        interval: const Duration(milliseconds: 500)
      ),
      CanTopic(
        id: 0x5C5,
        name: "Parking Brake & Odometer",
        bytes: 8,
        interval: const Duration(milliseconds: 100)
      ),
      CanTopic(
        id: 0x5E3,
        name: "Unknown",
        bytes: 4,
        interval: const Duration(milliseconds: 500)
      ),
      CanTopic(
        id: 0x5E4,
        name: "Unknown",
        bytes: 3,
        interval: const Duration(milliseconds: 100)
      ),
      CanTopic(
        id: 0x5EB,
        name: "Unknown",
        bytes: 8,
        interval: const Duration(milliseconds: 500)
      ),
      CanTopic(
        id: 0x5EB,
        name: "Unknown",
        bytes: 8,
        interval: const Duration(milliseconds: 500)
      ),
      CanTopic(
        id: 0x60D,
        name: "Doors & Vehicle State",
        bytes: 8,
        interval: const Duration(milliseconds: 100)
      ),
      CanTopic(
        id: 0x625,
        name: "Headlights Mode",
        bytes: 6,
        interval: const Duration(milliseconds: 100)
      ),
      CanTopic(
        id: 0x6F6,
        name: "Unknown",
        bytes: 3,
        interval: const Duration(milliseconds: 100)
      ),
      /*
      CanTopic(
        id: 0x793,
        name: "Charger",
        bytes: 8
      )
      */
    ]);

    registerTasks([
      ElmMonitorTask(
        name: "Driving: Speed & Motor Power",
        vehicle: this,
        priority: 2,
        maxDuration: const Duration(milliseconds: 500),
        isEnabled: () => metrics['gear']?.value > 0,
        topics: [
          _topics[0x284]!, // Speed
          _topics[0x176]!, // Motor Voltage
          _topics[0x180]!, // Motor Current
        ]
      ),
      ElmMonitorTask(
        name: "Driving: Shifter & Parking Brake",
        vehicle: this,
        maxDuration: const Duration(milliseconds: 100),
        interval: const Duration(milliseconds: 500),
        isEnabled: () => metrics['gear']?.value > 0 && metrics['speed']?.value < 15,
        topics: [
          _topics[0x421]!, // Shifter
          _topics[0x5C5]!, // Parking Brake
        ]
      ),
      ElmMonitorTask(
        name: "Driving: HV Battery",
        vehicle: this,
        maxDuration: const Duration(milliseconds: 250),
        interval: const Duration(seconds: 10),
        isEnabled: () => metrics['gear']?.value > 0,
        topics: [
          _topics[0x5B3]!, // HV Battery
        ]
      ),
      ElmMonitorTask(
        name: "Parked",
        vehicle: this,
        maxDuration: const Duration(milliseconds: 500),
        isEnabled: () => metrics['gear']?.value == 0,
        topics: [
          _topics[0x421]!, // Shifter
          _topics[0x5B3]!, // HV Battery
          _topics[0x5C5]!, // Park Brake & Odometer
          _topics[0x60D]!, // Doors
        ] 
      ),
      /*
      ElmPollTask(
        name: "Charger",
        vehicle: this,
        timeout: const Duration(seconds: 2),
        cooldown: const Duration(seconds: 5),
        isEnabled: () => metrics['gear']?.value == 0,
        header: 0x792,
        requests: ["03221210", "03221230"],
        responseTopic: _topics[0x793]!
      )
      */
    ]);
    
    registerMetrics([
      Metric(id: "powered", defaultValue: false),
      Metric(id: "gear"),
      Metric(id: "eco", defaultValue: false),
      Metric(id: "speed", defaultValue: 0.0),
      Metric(id: "fl_speed", defaultValue: 0.0),
      Metric(id: "fr_speed", defaultValue: 0.0),
      Metric(id: "motor_power", defaultValue: 0.0),
      Metric(id: "motor_current", defaultValue: 0.0),
      Metric(id: "motor_voltage", defaultValue: 0.0),
      Metric(id: "charge_power", defaultValue: 0.0),
      Metric(id: "charge_current", defaultValue: 0.0),
      Metric(id: "charge_voltage", defaultValue: 0.0),
      Metric(id: "charge_status"),
      Metric(id: "soh"),
      Metric(id: "gids"),
      Metric(id: "soc", defaultValue: 0.0),
      Metric(id: "range"),
      Metric(id: "range_at_last_charge"),
      Metric(id: "fan_speed", timeout: const Duration(seconds: 5)),
      Metric(id: "driver_door_open", defaultValue: false),
      Metric(id: "passenger_door_open", defaultValue: false),
      /*
      Metric(
        id: "indicating_left", 
        defaultValue: false, 
        timeout: const Duration(seconds: 5)
      ),
      Metric(
        id: "indicating_right", 
        defaultValue: false, 
        timeout: const Duration(seconds: 5)
      ),
      */
      Metric(id: "locked", defaultValue: false),
      Metric(id: "parking_brake_engaged", defaultValue: false),
      Metric(id: "odometer"),
      Metric(
        id: "gps_lock",
        defaultValue: false,
        timeout: const Duration(seconds: 30)
      ),
      Metric(id: "gps_distance", defaultValue: 0.0),
    ]);

    _initGps();
  }

  void registerMetric(Metric metric) {
    metric.onUpdate = metricUpdated;
    metrics[metric.id] = metric;
    model.log('Registered metric: ${metric.id}');
  }

  void registerMetrics(List<Metric> metrics) {
    for (var metric in metrics) {
      registerMetric(metric);
    }
  }

  void registerTopic(CanTopic topic) {
    _topics[topic.id] = topic;
    model.log('Registered topic: ${topic.idHex}');
  }

  void registerTopics(List<CanTopic> topics) {
    for (var topic in topics) {
      registerTopic(topic);
    }
  }

  void registerTask(ElmTask task) {
    _tasks.add(task);
    _taskQueue.add(task);
    model.log('Registered task: ${task.name}');
  }

  void registerTasks(List<ElmTask> tasks) {
    for (var task in tasks) {
      registerTask(task);
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
    
    } else if (metric.id == 'gear' && metric.value > 0 && metrics['range_at_last_charge']?.value == 0) {
      metrics['range_at_last_charge']?.setValue(metrics['range']?.value);
    
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
      final double soc = min((energyKwh/batteryCapacity)*100, 100);
      metrics['soc']?.setValue(soc);

    } else if (metric.id == 'range') {
      int range = metric.value;
      if (range > 0 && range <= 10) model.showAlert("low_range");

    } else if (metric.id == 'motor_current' || metric.id == 'motor_voltage') {
      double current = metrics['motor_current']?.value;
      double voltage = metrics['motor_voltage']?.value;

      // TODO: Fix current and voltage values so that division by 8.5 isn't needed.
      metrics['motor_power']?.setValue(((current * voltage) / 8.5) / 1000);

    } else if (metric.id == 'gps_lock' && metric.value == false) {
      speedLimit = null;
      displayedSpeedLimitAge = 999999;
      model.notify("speedLimit");

    } else if (metric.id == 'charge_current' || metric.id == 'charge_voltage') {
      final double current = metrics['charge_current']?.value;
      final double voltage = metrics['charge_voltage']?.value;
      final double powerKw = (current * voltage) / 1000;
      metrics['charge_power']?.setValue(powerKw);

      final Metric chargeStatus = metrics['charge_status']!;

      if (current > 0) {
        if (chargeStatus.value == 0) {
          chargeStatus.setValue(1);
          metrics['range_at_last_charge']?.setValue(0);
        }

        if (powerKw >= 1 && chargeStatus.value == 1) {
          chargeStatus.setValue(2);
        }

        if (powerKw == 0 && chargeStatus.value == 2) {
          chargeStatus.setValue(3);
        }

      } else {
        chargeStatus.setValue(0);
      }
    }
    
    model.notify(metric.id);
  }

  void processIncomingData(String data) {
    for (var char in data.characters) {
      //String char = String.fromCharCode(charCode);
      
      if (char == ">") {
        for (var command in _pendingCommands) {
          _completeCommand(command, true);
        }

      } else if (char == "\r") {
        if (_buffer.isNotEmpty) {
          model.log("RX: $_buffer");
          
          /*
          if (_buffer == "FULL") {
            if (_currentTask?.status == ElmTaskStatus.running) {
              sendCommand(ElmCommand("AT MA", timeout: const Duration(milliseconds: 50)));
            }

          } else {
            processFrame(_buffer);
          }
          */

          processFrame(_buffer);
          
          _buffer = "";
        }

      } else {
        _buffer += char;
      }
    }
  }

  void processFrame(String frame) {
    final CanTopic? frameTopic = 
      _topics.values.firstWhereOrNull((topic) => frame.startsWith(topic.idHex));

    if (frameTopic != null) {
      String frameDataStr = frame.substring(frameTopic.idHex.length);

      if (frameDataStr.length == frameTopic.bytes * 2) {
        model.log(frameTopic.name, category: 1);

        final RegExp exp = RegExp(r'.{2}');
        final Iterable<Match> matches = exp.allMatches(frameDataStr);
        final frameData = 
          matches.map((m) => int.tryParse(m.group(0) ?? '', radix: 16) ?? 0).toList();
        
        processTopicData(frameTopic, frameData);
        //_currentTask?.processTopicData(frameTopic, frameData);

        /*
        if (_currentTask != null && _pendingTopics.remove(frameTopic)) {
          model.log(_pendingTopics.map((t) => t.name).toList().toString(), category: 2);
          if (_pendingTopics.isEmpty) nextTask();
        }
        */
      } else {
        model.log('${frameTopic.name} (INVALID)', category: 1);
      }
    }
  }

  void processTopicData(CanTopic topic, List<int> data) {
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

    } else if (topic.id == 0x176) {
      final int rawVoltage = (data[2] << 8) | data[3];
      metrics['motor_voltage']?.setValue(rawVoltage / 20.0);
    
    } else if (topic.id == 0x180) {
      int rawCurrent = (data[2] << 8) | data[3];
      if ((rawCurrent & 0x8000) > 0) {
        rawCurrent = -(~rawCurrent & 0xFFFF);
      }

      metrics['motor_current']?.setValue(rawCurrent / 2.0);

    } else if (topic.id == 0x284) {
      double frontRightSpeed = ((data[0] << 8) | data[1]) / 208;
      double frontLeftSpeed = ((data[2] << 8) | data[3]) / 208;

      double speed = (frontRightSpeed + frontLeftSpeed) / 2;
      
      metrics['speed']?.setValue(speed);
      metrics['fl_speed']?.setValue(frontLeftSpeed);
      metrics['fr_speed']?.setValue(frontRightSpeed);

    } else if (topic.id == 0x5B3) {
      final int gids = ((data[4] & 0x01) << 8) | data[5];

      // Gids shows as high value on startup - this is incorrect, so we ignore it.
      if (gids < 500) metrics['gids']?.setValue(gids);
      
      metrics['soh']?.setValue(data[1] >> 1);

    } else if (topic.id == 0x54B) {
      metrics['fan_speed']?.setValue(data[4] >> 3);

    } else if (topic.id == 0x60D) {
      metrics['powered']?.setValue(((data[1] >> 1) & 0x03) == 3);
      metrics['driver_door_open']?.setValue((data[0] & 0x10) > 0);
      metrics['passenger_door_open']?.setValue((data[0] & 0x08) > 0);

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
      metrics['indicating_left']?.setValue((data[2] & 0x02) > 0);
      metrics['indicating_right']?.setValue((data[2] & 0x04) > 0);

    } else if (topic.id == 0x793) {
      final type = data[3];
      if (type == 0x10) {
        final current = ((data[4] << 8) | data[5]) / 16;
        if (current < 150) metrics['charge_current']?.setValue(current);

      } else if (type == 0x30) {
        final voltage = ((data[4] << 8) | data[5]) / 128;
        metrics['charge_voltage']?.setValue(voltage);
      }
    }
  }

  Future<bool> sendCommand(ElmCommand command) {
    model.log('TX: ${command.text}');
    _btConnection?.output.add(ascii.encode('${command.text}\r'));
    _socketConnection?.sendMessage('${command.text}\r');
    _pendingCommands.add(command);

    command.timer = Timer(command.timeout, () => _completeCommand(command, false));
    return command.completer.future;
  }

  void _completeCommand(ElmCommand command, bool gotPrompt) {
    if (command.completer.isCompleted) return;
    command.timer?.cancel();
    command.completer.complete(gotPrompt);
    _pendingCommands.remove(command);
  }

  Future<bool> nextTask() async {
    if (!connected) return false;

    if (_taskQueue.isNotEmpty) {
      final task = _taskQueue.first;
      _taskQueue.removeAt(0);

      if (task.isEnabled()) {
        model.log(task.name, category: 2);
        await task.run();
      }

      if (task.interval != null) {
        Future.delayed(task.interval!, () => _addTaskToQueue(task));
      } else {
        _addTaskToQueue(task);
      }
    }

    return true;
  }

  void _addTaskToQueue(ElmTask task) {
    if (task.priority != null) {
      final int index = min(task.priority! - 1, _taskQueue.length);
      _taskQueue.insert(index, task);
    } else {
      _taskQueue.add(task);
    }
  }

  void connect(ElmConnectionType connectionType) async {
    if (connected || connecting) return;

    connecting = true;
    model.notify('connecting');

    if (connectionType == ElmConnectionType.bluetooth) {
      if (_btAddress == null && await bluetoothSerial.isAvailable == true) {
        var bondedDevices = await bluetoothSerial.getBondedDevices();
        if (bondedDevices.isNotEmpty) {
          _btAddress = bondedDevices[0].address;
        }
      }

      if (_btAddress != null) {
        model.log('Connecting to $_btAddress');
        
        //final pos = await _determinePosition();
        //model.log('${pos.latitude}, ${pos.longitude}');

        try {
          var connection = await BluetoothConnection.toAddress(_btAddress);
          if (connection.isConnected) {
            connected = true;
            _btConnection = connection;
            connection.input?.listen(
              (charCodes) => processIncomingData(String.fromCharCodes(charCodes))
            );
          }

        } catch (exception) {
          debugPrint(exception.toString());
        }
      }

    } else if (connectionType == ElmConnectionType.wifi) {
      _socketConnection = TcpSocketConnection("192.168.0.10", 35000);
      if (await _socketConnection!.canConnect(5000)) {
        await _socketConnection!.connect(5000, processIncomingData);
        connected = true;
      }
    }

    connecting = false;
    model.notify('connecting');

    if (connected) {
      model.log('Connected!');
      
      Future.delayed(const Duration(milliseconds: 50), () async {
        model.log('Initializing...');
        await sendCommand(ElmCommand("AT Z"));
        await Future.delayed(const Duration(seconds: 2));
        await sendCommand(ElmCommand("AT E0"));
        await sendCommand(ElmCommand("AT S0"));
        await sendCommand(ElmCommand("AT L0"));
        await sendCommand(ElmCommand("AT H1"));
        await sendCommand(ElmCommand("AT SP6"));
        await sendCommand(ElmCommand("AT CAF0"));
        await sendCommand(ElmCommand("AT ST 0C"));
        //await _sendCommand(Command("AT CF 000"));
        //await sendCommand("AT CM 048");
        model.log("Initialized!");
        
        Future.doWhile(nextTask);
      });

      model.notify('connected');
    } else {
      model.log('Connection failed!');
      //Future.delayed(const Duration(milliseconds: 500), connect);
    }
  }

  void disconnect() async {
    if (!connected) return;

    //_currentTask = null;
    //_commandTimer?.cancel();

    //sendCommand(ElmCommand("STOP", validResponses: ['STOPPED', '?']));
    await sendCommand(ElmCommand("AT Z"));

    _btConnection?.close();
    _btConnection?.dispose();
    _btConnection = null;

    _socketConnection?.disconnect();
    _socketConnection = null;
    
    connected = false;
    model.notify('connected');

    //commandQueue.clear();
    //metrics.clear();

    model.log('Disconnected!');
  }

  /*
  void reconnect() {
    if (connecting) return;

    disconnect(); connect();
  }
  */

  void dispose() {
    disconnect();
    _positionSubscription.cancel();
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

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 1
    );

    _positionSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
    (Position? position) {
      debugPrint(position.toString());
      metrics['gps_lock']?.setValue(position != null);
      if (position == null) return;

      _updatePosition(position.latitude, position.longitude);
    });
  }

  void _updatePosition(double lat, double lng) {
    const distance = Distance();
    final oldPos = position;
    final newPos = LatLng(lat, lng);

    if (oldPos != null) {
      final double distanceKm = distance.as(
        LengthUnit.Meter,
        oldPos,
        newPos
      ) / 1000;

      Bearing bearing = getBearingBetweenPoints(oldPos, newPos);
      bearingRad = bearing.radians;
      bearingDeg = bearing.degrees;

      debugPrint("$oldPos -> $newPos = $bearingDeg");
      model.updateMap(newPos, bearingDeg);

      if (distanceKm <= 100) {
        final double gpsDistance = metrics['gps_distance']?.value ?? 0.0;
        metrics['gps_distance']?.setValue(gpsDistance + distanceKm);
      }

    } else {
      model.updateMap(newPos, 0);
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
