
import 'package:candle_dash/themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:property_change_notifier/property_change_notifier.dart';
import 'package:candle_dash/vehicle.dart';
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

  // Initally set to 100 so it starts as light mode.
  int _luxValue = 100;

  final PageController hPageController = PageController(
    initialPage: 0,
    keepPage: true
  );

  final PageController vPageController = PageController(
    initialPage: 0,
    keepPage: true,
    viewportFraction: 0.95
  );

  bool drawerOpen = false;
  int vPage = 0;

  final AudioCache audioPlayer = AudioCache();

  late AnimationController mapAnimController;
  late MapController mapController;
  late Animation<double> mapAnim;
  late Tween<double> mapLatTween;
  late Tween<double> mapLngTween;
  late Tween<double> mapRotTween;
  LatLng mapPosition = LatLng(0, 0);
  double mapRotation = 0;

  AppModel() {
    vehicle = Vehicle(this);
  }

  void init() {
    _light = Light();
    try {
      _light.lightSensorStream.listen(onLightData);
    } on LightException catch (exception) {
      debugPrint(exception.toString());
    }
  }

  @override
  void dispose() {
    vehicle.close();
    super.dispose();
  }

  void newMap(MapController mController, AnimationController aController) {
    mController.onReady.then((v) {
      aController.addListener(() {
        var rotation = mapRotTween.evaluate(mapAnim);
        if (rotation > 360) {
          rotation -= 360;
        } else if (rotation < 0) {
          rotation += 360;
        }

        mController.moveAndRotate(
          LatLng(
            mapLatTween.evaluate(mapAnim), 
            mapLngTween.evaluate(mapAnim)
          ), 
          mController.zoom,
          rotation
        );
      });
      
      mapController = mController;
      mapAnimController = aController;
    });
  }

  void tweenMap(LatLng newPosition, double newRotation) {
    /// Only update map position if the drawer is open and on the correct
    /// page. This stops the issue where the controller errors because the
    /// map widget doesn't exist.
    if (drawerOpen && vPage == 0) {
      mapLatTween = Tween<double>(
        begin: mapPosition.latitude, end: newPosition.latitude
      );
      mapLngTween = Tween<double>(
          begin: mapPosition.longitude, end: newPosition.longitude
      );

      /// This logic is a bit weird, but it's to prevent the map from doing a
      /// large rotation when not necessary. For example:
      /// 
      /// If the map is rotating from 20 to 320 degrees, instead of doing a
      /// 300 degree rotation from 20 to 230, it will do a 50 degree rotation
      /// from 20 to -30. This stops the map from flipping back and forth when
      /// the rotation crosses over 360 degrees.
      
      final normalMag = (newRotation - mapRotation).abs();
      final crossPositiveMag = (360 + newRotation) - mapRotation;
      final crossNegativeMag = mapRotation + (360 - newRotation);

      var tweenRotation = newRotation;

      if (crossPositiveMag < normalMag) {
        tweenRotation = 360 + newRotation;
      } else if (crossNegativeMag < normalMag) {
        tweenRotation = 360 - newRotation;
      }

      mapRotTween = Tween<double>(
          begin: mapRotation, end: tweenRotation
      );
      
      mapAnim =
        CurvedAnimation(parent: mapAnimController, curve: Curves.fastOutSlowIn);
      mapAnimController.reset();
      mapAnimController.forward();
    }

    mapPosition = newPosition;
    mapRotation = newRotation;
  }

  void onLightData(int luxValue) {
    _luxValue = luxValue;
  }

  void hPageChanged(int page) {
    drawerOpen = (page == 1);
    clusterOffset = !drawerOpen ? const Offset(0,0) : const Offset(-0.235, 0);
    
    if (drawerOpen) {
      if (vPageController.hasClients) {
        // Animate the vertical pageview to the previously recorded vertical
        // page index. This is a temporary fix for the issue where it returns
        // to the first page upon being rebuilt.
        vPageController.animateToPage(
          vPage, 
          duration: const Duration(milliseconds: 250), 
          curve: Curves.easeInOutQuad
        );
      }
    }
    
    notify("clusterOffset");
  }

  void vPageChanged(int page) {
    vPage = page;
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
    timeUnit = parts[1].toLowerCase();
    notify('time');
  }

  /*void updateMap(LatLng pos) {
    print(pos);
    mapController.move(pos, mapController.zoom);
  }*/
  
  void notify(String? property) => notifyListeners(property);
}