import 'dart:async';
import 'dart:convert';

import 'package:candle_dash/can.dart';
import 'package:candle_dash/constants.dart';
import 'package:candle_dash/model.dart';
import 'package:candle_dash/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:latlong2/latlong.dart';
import 'package:wakelock/wakelock.dart';

FlutterBluetoothSerial bluetoothSerial = FlutterBluetoothSerial.instance;

class Vehicle {
  late AppModel model;

  late List<Topic> topics;
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
  //bool waitingForReply = false;
  Completer? sendCompleter;
  String? lastCommand;
  Topic? currentTopic;
  //List<String> commandQueue = [];

  Vehicle(this.model) {
    pTracking = PerformanceTracking(this, [20, 40, 60, 80, 100]);

    topics = [
      /*
      Topic(
        id: 0x174,
        name: "VCM",
        intervalMs: 10,
        highPriority: true
      ),
      */
      Topic(
        id: 0x284,
        name: "ABS",
        intervalMs: 25,
        highPriority: true
      )
    ];
    
    registerMetrics([
      Metric(id: "powered"),
      Metric(id: "gear"),
      Metric(id: "speed")
    ]);
  }

  void registerMetrics(List<Metric> metrics) {
    for (var metric in metrics) {
      metric.onUpdate = metricUpdated;
      this.metrics[metric.id] = metric;
      debugPrint('Registered metric: ${metric.id}');
    }
  }

  dynamic getMetric(String id) {
    return metrics[id]?.value ?? 0;
  }

  bool getMetricBool(String id) {
    return metrics[id]?.value == 1 ? true : false;
  }

  double getMetricDouble(String id) {
    // Ensures the value is a double, not a int.
    return (metrics[id]?.value ?? 0) + .0;
  }

  void metricUpdated(Metric metric) {
    if (metric.id == 'powered') {
      if (metric.value == 1) {
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
        final int now = DateTime.now().millisecondsSinceEpoch;

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
        debugPrint("RX: $msg");

        if (currentTopic != null) {
          RegExp exp = RegExp(r'.{2}');
          Iterable<Match> matches = exp.allMatches(msg);
          var frameData = 
            matches.map((m) => int.tryParse(m.group(0) ?? '', radix: 16) ?? 0).toList();
          
          processFrame(currentTopic!, frameData);
        }

        if (msg != lastCommand) { // Ignore echo
          sendCompleter?.complete();
          sendCompleter = null;
        }

        buffer = "";
      }
    }
  }

  void processFrame(Topic topic, List<int> data) {
    if (topic.id == 0x174) {
      int gear = 0;

      switch (data[3]) {
        case 170: // Park/Neutral
          gear = 1;
          break;
        
        case 187: // Drive
          gear = 4;
          break;

        case 153: // Reverse
          gear = 2;
          break;
      }

      metrics['gear']?.setValue(gear);

    } else if (topic.id == 0x284) {
      double frontRightSpeed = ((data[0] << 8) | data[1]) / 208;
      double frontLeftSpeed = ((data[2] << 8) | data[3]) / 208;

      double speed = (frontRightSpeed + frontLeftSpeed) / 2;
      metrics['speed']?.setValue(speed);
    }
  }

  Future<void> sendCommand(String command, {bool waitForResponse = true}) async {
    debugPrint("TX: $command");

    command = command.replaceAll(' ', '');
    lastCommand = command;
    
    btConnection?.output.add(ascii.encode('$command\r'));
    
    if (waitForResponse) {
      sendCompleter = Completer<void>();
      return sendCompleter!.future;
    }
  }

  /*
  void queueCommand(String command, {bool waitForResponse = true}) {
    commandQueue.add(command);
    processQueue();
  }
  */

  /*
  void processQueue() {
    if (commandQueue.isEmpty) return;

    String command = commandQueue.first;
    commandQueue.removeAt(0);
    sendCommand(command);
  }
  */

  void connect() async {
    if (connected || connecting) return;

    if (btAddress == null) {
      var bondedDevices = await bluetoothSerial.getBondedDevices();
      if (bondedDevices.isNotEmpty) {
        btAddress = bondedDevices[0].address;
      }
    }

    if (btAddress != null) {
      connecting = true;
      debugPrint('[bluetooth] connecting to $btAddress');

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

    if (connected) {
      debugPrint('[bluetooth] connected!');
      model.notify('connected');

      metrics['powered']?.setValue(1);
      metrics['gear']?.setValue(4);
      metrics['speed']?.setValue(99);
      
      //Future.delayed(const Duration(milliseconds: 500), () async {
      await sendCommand("AT Z");
      await sendCommand("AT E0");
      await sendCommand("AT SP6");
      await sendCommand("AT CAF0");
      await sendCommand("AT S0");
      initialized = true;
      
      await sendCommand("AT CRA 284");
      await sendCommand("AT MA", waitForResponse: false);
      currentTopic = topics.first;
      //});

    } else {
      debugPrint('[bluetooth] connection failed!');
      Future.delayed(const Duration(milliseconds: 500), () {
        reconnect();
      });
    }
  }

  void close() async {
    if (!connected) return;

    currentTopic = null;
    await sendCommand("AT MA");
    await sendCommand("AT Z");

    initialized = false;
    connected = false;

    btConnection?.close();
    btConnection = null;
    sendCompleter = null;

    //commandQueue.clear();
    //metrics.clear();

    debugPrint('[bluetooth] closed');

    model.notify('connected');
  }

  void reconnect() {
    if (connecting) return;

    close(); connect();
  }
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
