import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dash_delta/constants.dart';
import 'package:dash_delta/model.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:wakelock/wakelock.dart';

class Vehicle {
  late AppModel model;

  var metrics = <String, List<dynamic>>{};

  bool connected = false;
  bool connecting = false;
  bool initialized = false;

  late IOWebSocketChannel socket;

  late PerformanceTracking pTracking;

  String ip = Constants.prodIp;

  Vehicle(this.model) {
    pTracking = PerformanceTracking(this, [20, 40, 60, 80, 100]);
  }

  dynamic getMetric(String id, [int index = 0]) {
    return metrics[id]?[index] ?? 0;
  }

  bool getMetricBool(String id, [int index = 0]) {
    return metrics[id]?[index] == 1 ? true : false;
  }

  double getMetricDouble(String id, [int index = 0]) {
    // Ensures the value is a double, not a int.
    return (metrics[id]?[index] ?? 0) + .0;
  }

  void metricUpdated(String id, List<dynamic> data) {
    if (id == 'powered') {
      if (data[0] == 1) {
        Wakelock.enable();
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

        // So we will start on the map page next time the drawer is opened.
        model.vPage = 0;
      }
    } else if (id == 'rear_speed') {
      pTracking.update(data[0] / 1);
    
    } else if (id == 'gps_position' && data.length == 2) {
      const distance = Distance();
      final pointA = model.mapPosition;
      final pointB = LatLng(data[0] + .0, data[1] + .0);
      
      final double distanceM = distance.as(
        LengthUnit.Meter,
        pointA,
        pointB
      );

      /// Update the map only if the vehicle has moved at least 5 meters.
      /// This stops the map from moving a rotating when the vehicle is not
      /// moving.
      if (distanceM >= 5) {
        // This 
        final deltaLng = pointB.longitude - pointA.longitude;
        
        final x = cos(pointB.latitude) * sin(deltaLng);
        final y = 
          cos(pointA.latitude) * sin(pointB.latitude) - sin(pointA.latitude)
          * cos(pointB.latitude) * cos(deltaLng);


        final angle = atan2(x, y) * (180 / pi);

        model.tweenMap(pointB, -angle);
      }
    }
   
    model.notify(id);
  }

  void process(String data) {
    final decodedData = jsonDecode(data);
    if (initialized) {
      int index = decodedData[0];
      List<dynamic> values = decodedData[1];
      
      String id = metrics.keys.elementAt(index);
      metrics[id] = values;
      metricUpdated(id, values);
    } else {
      /// This means the data is the first message from the websocket. The first
      /// message contains a list of metric ids seperated by commas. We can use
      /// this list to assign a starting value of [0] for each metric.

      List<String> ids = List.castFrom(decodedData);

      for (var id in ids) {
        metrics[id] = [0];
      }

      initialized = true;
    }
  }

  void connect() async {
    if (connected || connecting) return;

    connecting = true;
    debugPrint('[websocket] connecting...');

    try {
      final ws = await WebSocket
        .connect('ws://$ip:8080/ws') //10.1.1.20 10.1.2.57 192.168.1.1
        .timeout(const Duration(seconds: 5));

      debugPrint('[websocket] connected!');
      socket = IOWebSocketChannel(ws);

      connecting = false; connected = true;

      const jsonEncoder = JsonEncoder();

      final subscribeMsg = {
        'event': 'subscribe',
        'topic': 'metrics'
      };

      ws.add( jsonEncoder.convert(subscribeMsg) );

      model.notify('connected');
      //this.car.model.update();

      socket.stream.listen((data) {
        process(data);
      },
        onDone: () => reconnect()
      );

      //socket.sink.add('subscribe_binary');
    } catch (exception) {
      connecting = false;
      Future.delayed(const Duration(milliseconds: 500), () {
        reconnect();
      });
      debugPrint('[websocket] connection failed!');
    }
  }

  void close() {
    if (!connected) return;

    socket.sink.close(status.goingAway);
    connected = false;
    initialized = false;

    debugPrint('[websocket] closed');

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

  PerformanceTracking(this.vehicle, this.milestoneSpeeds);

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