import 'dart:convert';
import 'dart:io';

import 'package:dash_delta/constants.dart';
import 'package:dash_delta/model.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:wakelock/wakelock.dart';

class Vehicle {
  late AppModel model;

  var metrics = <String, dynamic>{};

  bool connected = false;
  bool connecting = false;
  bool initialized = false;

  late IOWebSocketChannel socket;

  late PerformanceTracking pTracking;

  String ip = Constants.prodIp;

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

  void metricUpdated(String id, dynamic value) {
    if (id == 'powered') {
      value == 1 ? Wakelock.enable() : Wakelock.disable();
    } else if (id == 'rear_speed') {
      pTracking.update(value / 1);
    } else if (id == 'gear') {
      if (value != 4) pTracking.setTracking(false);
    }
    model.notify(id);
  }

  void process(String data) {
    //print(data);
    var decoded = jsonDecode(data);

    if (initialized) {
      int index = decoded[0];
      dynamic value = decoded[1];

      String id = metrics.keys.elementAt(index);
      metrics[id] = value;
      metricUpdated(id, value);
    } else {
      // This means the data is the first message from the websocket.
      List<String> ids = List.castFrom(decoded);

      for (var id in ids) {
        metrics[id] = 0;
      }
      initialized = true;
    }
    //model.text = metrics.toString();
    //model.update();
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
    //metrics.clear();

    debugPrint('[websocket] closed');

    model.notify('connected');

    //this.car.reset();
    //this.car.model.update();
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