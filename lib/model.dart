import 'dart:async';

import 'package:dash_delta/themes.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:property_change_notifier/property_change_notifier.dart';
import 'package:dash_delta/vehicle.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:light/light.dart';

class AppModel extends PropertyChangeNotifier<String> {
  late Vehicle vehicle;

  String time = "";
  String timeUnit = "";

  Offset clusterOffset = const Offset(0,0);

  ThemeData theme = Themes.light;
  bool _autoTheme = true;

  late Light _light;
  late StreamSubscription _lightSub;

  // Initally set to 100 so it starts as light mode.
  int _luxValue = 100;

  PageController hPageController = PageController(
    initialPage: 0,
    keepPage: true
  );

  PageController vPageController = PageController(
    initialPage: 0,
    keepPage: true,
    viewportFraction: 0.95
  );

  int _vPage = 0;

  AudioCache audioPlayer = AudioCache();

  AppModel() {
    vehicle = Vehicle(this);
  }

  void init() {
    _light = Light();
    try {
      _lightSub = _light.lightSensorStream.listen(onLightData);
    } on LightException catch (exception) {
      debugPrint(exception.toString());
    }
  }

  void onLightData(int luxValue) {
    _luxValue = luxValue;
  }

  void hPageChanged(int page) {
    final active = (page == 1);
    clusterOffset = !active ? const Offset(0,0) : const Offset(-0.21, 0);
    
    if (active) {
      if (vPageController.hasClients) {
        // Animate the vertical pageview to the previously recorded vertical
        // page index. This is a temporary fix for the issue where it returns
        // to the first page upon being rebuilt.
        /*
        vPageController.animateToPage(
          _vPage, 
          duration: const Duration(milliseconds: 250), 
          curve: Curves.easeInOutQuad
        );
        */
      }
    }
    

    notify("clusterOffset");
  }

  void vPageChanged(int page) {
    _vPage = page;
  }
  
  void setTheme(ThemeData? newTheme) {
    if (newTheme != null) {
      theme = newTheme;
      notify("theme");
    }
  }

  void setAutoTheme(bool value) {
    _autoTheme = value;
    if (value) {
      updateTheme();
      notify("theme");
    }
  }

  void updateTheme() {
    if (_autoTheme) {
      if (_luxValue >= 30) {
        setTheme(Themes.light);
      } else {
        setTheme(Themes.dark);
      }
    }
  }

  void updateTime() {
    DateTime now = DateTime.now();
    String fullTime = DateFormat.jm().format(now);
    List<String> parts = fullTime.split(' ');
    
    time = parts[0];
    timeUnit = parts[1];
    notify('time');
  }
  
  void notify(String? property) => notifyListeners(property);
}