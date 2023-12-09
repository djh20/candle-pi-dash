import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:candle_dash/constants.dart';
import 'package:candle_dash/model.dart';
import 'package:candle_dash/utils.dart';
import 'package:eventsource/eventsource.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:wakelock/wakelock.dart';

class Vehicle {
  late AppModel model;

  var metrics = <String, dynamic>{};

  bool connected = false;
  bool connecting = false;
  //bool initialized = false;

  //late IOWebSocketChannel socket;
  EventSource? eventSource;

  late PerformanceTracking pTracking;

  String host = Constants.defaultHost;

  //Street? street;
  int? speedLimit;
  int? displayedSpeedLimit;
  int displayedSpeedLimitAge = 0;

  double bearingRad = 0;
  double bearingDeg = 0;

  Timer? _socketTimer;
  late final Timer _connectTimer;
  bool allowConnection = true;

  StreamSubscription<Position>? _positionSubscription;
  bool gpsLock = false;
  LatLng? gpsPosition;
  double gpsDistance = 0;

  Vehicle(this.model) {
    pTracking = PerformanceTracking(this, [20, 40, 60, 80, 100]);
    _connectTimer = Timer.periodic(const Duration(seconds: 1), (t) => onConnectTimer());
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
        //model.showAlert("experimental");

      } else {
        Wakelock.disable();
        pTracking.setTracking(false);
        
        /*
        // Close drawer
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

    } else if (ids.contains("charge_status") && metrics["charge_status"] > 0) {
      gpsDistance = 0;
      model.notify("gps");
    }
   
    for (var id in ids) {
      model.notify(id);
    }
  }

  void restartSocketTimer() {
    _socketTimer?.cancel();
    _socketTimer = Timer(const Duration(seconds: 5), () => disconnect());
  }

  void process(String data) {
    restartSocketTimer();
    final decodedData = jsonDecode(data);
    List<String> updatedMetrics = [];
    
    decodedData.forEach((id, value) {
      if (metrics[id] != value) {
        metrics[id] = value;
        updatedMetrics.add(id);
      }
    });

    metricsUpdated(updatedMetrics);
  }

  void connect() async {
    if (connected || connecting) return;

    connecting = true;
    debugPrint('[sse] connecting...');

    try {
      /*
      final ws = await WebSocket
        .connect('ws://$host/ws')
        .timeout(const Duration(seconds: 5));

      ws.pingInterval = const Duration(seconds: 2);

      debugPrint('[sse] connected!');
      socket = IOWebSocketChannel(ws);
      */
      eventSource = await EventSource.connect('http://$host/events');
      eventSource?.listen(
        (event) { 
          if (event.data == null) return;
          process(event.data!);
        }
      );
      restartSocketTimer();

      connecting = false; connected = true;
      _initGps();
      debugPrint('[sse] connected');
      
      model.notify('connected');

    } catch (exception) {
      debugPrint(exception.toString());
      connecting = false;
      /*
      Future.delayed(const Duration(milliseconds: 500), () {
        reconnect();
      });
      */
      debugPrint('[sse] connection failed!');
    }
  }

  void disconnect() {
    if (!connected) return;

    _socketTimer?.cancel();
    eventSource?.client.close();
    connected = false;
    //initialized = false;
    metrics.clear();
    _positionSubscription?.cancel();

    debugPrint('[sse] disconnected');

    model.notify('connected');
  }

  /*
  void reconnect() {
    if (connecting) return;

    disconnect(); connect();
  }
  */

  void onConnectTimer() {
    if (!connected && !connecting && allowConnection) {
      connect();
    
    } else if (connected && !allowConnection) {
      disconnect();
    }
  }

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
      distanceFilter: 30
    );

    _positionSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
    (Position? position) {
      debugPrint(position.toString());
      _setGpsLock(position != null);
      if (position == null) return;

      _updatePosition(position.latitude, position.longitude);
    });
  }

  void _setGpsLock(bool lock) {
    if (!lock) {
      speedLimit = null;
      displayedSpeedLimitAge = 999999;
      model.notify("speedLimit");
    }
    gpsLock = lock;
    model.notify("gps");
  }

  void _updatePosition(double lat, double lng) {
    const distance = Distance();
    final oldPos = gpsPosition;
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

      int gear = getMetric("gear");

      if (distanceKm <= 100 && gear > 0) {
        debugPrint("MOVED $distanceKm KM");
        gpsDistance += distanceKm;
      }

    } else {
      model.updateMap(newPos, 0);
    }

    gpsPosition = newPos;
    model.notify("gps");
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