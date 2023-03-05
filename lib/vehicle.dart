import 'dart:convert';
import 'dart:io';

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

  var metrics = <String, dynamic>{};

  bool connected = false;
  bool connecting = false;
  //bool initialized = false;

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
  bool waitingForReply = false;
  String? lastCommand;
  List<String> commandQueue = [];

  Vehicle(this.model) {
    pTracking = PerformanceTracking(this, [20, 40, 60, 80, 100]);
  }

  dynamic getMetric(String id) {
    return metrics[id] ?? 0;
  }

  bool getMetricBool(String id) {
    return metrics[id] == 1 ? true : false;
  }

  double getMetricDouble(String id) {
    // Ensures the value is a double, not a int.
    return (metrics[id] ?? 0) + .0;
  }

  void metricsUpdated(List<String> ids) {
    if (ids.contains("powered")) {
      if (metrics["powered"] == 1) {
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
    } else if (ids.contains("speed")) {
      final double speed = metrics["speed"] / 1;
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
      
    } else if (ids.contains("fan_speed") && metrics["fan_speed"] > 0) {
      model.showAlert("cc_on");
    
    } else if (ids.contains("range")) {
      int range = metrics["range"];
      if (range > 0 && range <= 10) model.showAlert("low_range");

    } else if (ids.contains("gps_lat") || ids.contains("gps_lng")) {
      double lat = metrics["gps_lat"];
      double lng = metrics["gps_lng"];

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

    } else if (ids.contains("gps_lock") && metrics["gps_lock"] == 0) {
      speedLimit = null;
      displayedSpeedLimitAge = 999999;
      model.notify("speedLimit");
    }
   
    for (var id in ids) {
      model.notify(id);
    }
  }

  void process(Uint8List data) {
    /*
    final decodedData = jsonDecode(data);
    List<String> updatedMetrics = [];
    
    decodedData.forEach((id, value) {
      if (metrics[id] != value) {
        metrics[id] = value;
        updatedMetrics.add(id);
      }
    });

    metricsUpdated(updatedMetrics);
    */
    for (var charCode in data) {
      if (charCode != 13) {
        buffer += String.fromCharCode(charCode);

      } else if (buffer.isNotEmpty) {
        String msg = buffer.replaceAll('>', '');
        //debugPrint("[bluetooth] RX: $msg");

        if (lastCommand == "ATMA" && msg.length == 8*2) {
          RegExp exp = RegExp(r'.{2}');
          Iterable<Match> matches = exp.allMatches(msg);
          var frameData = 
            matches.map((m) => int.tryParse(m.group(0) ?? '', radix: 16) ?? 0).toList();
            
          debugPrint('$frameData');
          
          double frontRightSpeed = ((frameData[0] << 8) | frameData[1]) / 208;
          double frontLeftSpeed = ((frameData[2] << 8) | frameData[3]) / 208;

          double speed = (frontRightSpeed + frontLeftSpeed) / 2;
          if (metrics['speed'] != speed) {
            metrics['speed'] = speed;
            metricsUpdated(['speed']);
          }
        }

        if (msg != lastCommand) { // Ignore echo
          waitingForReply = false;
          processQueue();
        }

        buffer = "";
      }
    }
  }

  void sendCommand(String command) {
    command = command.replaceAll(' ', '').replaceAll('>', '');
    lastCommand = command;
    debugPrint("[bluetooth] TX: $command");
    btConnection?.output.add(ascii.encode('$command\r'));
  }

  void queueCommand(String command) {
    commandQueue.add(command);
    processQueue();
  }

  void processQueue() {
    if (commandQueue.isEmpty || waitingForReply) return;

    String command = commandQueue.first;
    commandQueue.removeAt(0);
    waitingForReply = true;
    sendCommand(command);
  }

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
          connection.input?.listen(process);
        }

      } catch (exception) {
        debugPrint(exception.toString());
      }

      connecting = false;
    }

    if (connected) {
      debugPrint('[bluetooth] connected!');
      model.notify('connected');
      queueCommand("AT Z");
      queueCommand("AT E0");
      queueCommand("AT SP6");
      queueCommand("AT CAF0");
      queueCommand("AT S0");
      queueCommand("AT CRA 284");
      queueCommand("AT MA");

      metrics['powered'] = 1;
      metrics['gear'] = 4;
      metrics['speed'] = 99;

      metricsUpdated(['powered', 'gear', 'speed']);
      
    } else {
      debugPrint('[bluetooth] connection failed!');
      Future.delayed(const Duration(milliseconds: 500), () {
        reconnect();
      });
    }
  }

  void close() {
    if (!connected) return;

    connected = false;
    sendCommand("AT MA");
    btConnection?.close();
    btConnection = null;
    
    waitingForReply = false;
    commandQueue.clear();
    metrics.clear();

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