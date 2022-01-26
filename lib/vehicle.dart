import 'dart:convert';
import 'dart:io';

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

  Vehicle(this.model);

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
        .connect('ws://10.1.2.57:8080/ws')
        .timeout(const Duration(seconds: 5));

      debugPrint('[websocket] connected!');
      socket = IOWebSocketChannel(ws);

      connecting = false; connected = true;

      model.notify('connection_status');
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

    model.notify('connection_status');

    //this.car.reset();
    //this.car.model.update();
  }

  void reconnect() {
    if (connecting) return;

    close(); connect();
  }
}