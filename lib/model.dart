
import 'dart:convert';
import 'dart:math';

import 'package:candle_dash/constants.dart';
import 'package:candle_dash/themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  /// Used for moving the cluster to the side when the drawer is open.
  EdgeInsets clusterPadding = EdgeInsets.zero;

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

  List<Street> streets = [];

  AppModel() {
    vehicle = Vehicle(this);
  }

  void init() async {
    _light = Light();
    try {
      _light.lightSensorStream.listen(onLightData);
    } on LightException catch (exception) {
      debugPrint(exception.toString());
    }

    final String rawStreetData = 
      await rootBundle.loadString('assets/map/streets.geojson');
    
    final streetData = await jsonDecode(rawStreetData);
    final features = streetData['features'];

    for (var feature in features) {
      // If the feature is a street, add it to the list of streets.
      if (feature['geometry']['type'] == 'LineString') {
        final street = Street.fromFeature(feature);
        streets.add(street);
      }
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

  void updateMap(LatLng newPosition, double newRotation) {
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
        tweenRotation = -crossNegativeMag;
      }

      mapRotTween = Tween<double>(
          begin: mapRotation, end: tweenRotation
      );

      //print('$mapRotation -> $newRotation ($tweenRotation)');
      
      mapAnim =
        CurvedAnimation(parent: mapAnimController, curve: Curves.fastOutSlowIn);
      mapAnimController.reset();
      mapAnimController.forward();
    }

    final speedLimit = getSpeedLimit(newPosition, vehicle.speedLimit);

    if (speedLimit != null) {
      vehicle.lastSpeedLimit = speedLimit;
    }
    
    vehicle.speedLimit = speedLimit;

    notify("speedLimit"); 

    mapPosition = newPosition;
    mapRotation = newRotation;
  }

  int? getSpeedLimit(LatLng position, int? currentSpeedLimit) {
    const R = Constants.earthRadius;

    final latRad = position.latitudeInRad;
    final lngRad = position.longitudeInRad;

    final List<double> offsets = [10, 40, 60];

    final List<StreetPoint> points = []; 
    final List<int> speedLimits = [];

    // Get all the points that are within 160m of the main position.
    for (var street in streets) {
      for (var pointPos in street.pointPositions) {
        final distance = getDistance(position, pointPos);

        if (distance <= 160) {
          points.add( StreetPoint(pointPos, street) );
        }
      }
    }

    // Get the closest point for each offset.
    for (var offset in offsets) {
      final offsetLatRad = asin( 
        sin(latRad) * cos(offset/R) + 
        cos(latRad) * sin(offset/R)* cos(vehicle.bearingRad)
      );

      final offsetLngRad = 
        lngRad + atan2(
          sin(vehicle.bearingRad) * sin(offset/R)* cos(latRad), 
          cos(offset/R) - sin(latRad)* sin(offsetLatRad)
        );

      final offsetPos = LatLng(
        offsetLatRad * (180/pi),
        offsetLngRad * (180/pi)
      );

      StreetPoint? closestPoint;
      double closestDistance = 90;
      
      for (var point in points) {
        final distance = getDistance(offsetPos, point.position);

        if (distance < closestDistance) {
          closestPoint = point;
          closestDistance = distance;
        }
      }

      if (closestPoint != null && closestPoint.street.speedLimit != null) {
        speedLimits.add(closestPoint.street.speedLimit ?? 0);
      }
    }

    //speedLimits.clear();
    debugPrint(speedLimits.toString());

    if (speedLimits.isNotEmpty) {
      // We need to have at least two speed limits to be confident enough.
      if (speedLimits.length >= 2) {
        final consensus = speedLimits.every((v) => v == speedLimits[0]);

        // Only update the speed limit if the offset speed limits are the same.
        // Otherwise, return the current speed limit so it doesn't change.
        if (consensus) {
          return speedLimits[0];
        }
      }
      return currentSpeedLimit;
    }
 
    return null;
  }

  double getDistance(LatLng posA, LatLng posB) {
    const R = Constants.earthRadius;
  
    final aLatRad = posA.latitudeInRad;
    final aLngRad = posA.longitudeInRad;

    final bLatRad = posB.latitudeInRad;
    final bLngRad = posB.longitudeInRad;
    
    final x = (bLngRad-aLngRad) * cos((aLatRad+bLatRad)/2);
    final y = (bLatRad-aLatRad);
    final d = sqrt(x*x + y*y) * R;

    return d;
  }

  
  void onLightData(int luxValue) {
    _luxValue = luxValue;
  }

  void hPageChanged(int page) {
    drawerOpen = (page == 1);

    clusterPadding = 
      !drawerOpen ? 
      EdgeInsets.zero : 
      const EdgeInsets.only(right: Constants.drawerWidth);
    
    if (drawerOpen) {
      if (vPageController.hasClients) {
        // Animate the vertical pageview to the previously recorded vertical
        // page index. This is a temporary fix for the issue where it returns
        // to the first page upon being rebuilt.
        vPageController.animateToPage(
          vPage, 
          duration: const Duration(milliseconds: 300), 
          curve: Curves.easeInOutQuad
        );
      }
    }
    
    notify("drawer");
  }

  void vPageChanged(int page) {
    vPage = page;
  }
  
  void setTheme(ThemeData? newTheme) {
    if (newTheme != null && theme != newTheme) {
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
      if (_luxValue >= 60) {
        setTheme(Themes.light);
      } else if (_luxValue <= 26) {
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

  void notify(String? property) => notifyListeners(property);
}

class Street {
  final String? name;
  final int? speedLimit;
  final List<LatLng> pointPositions;

  Street(this.name, this.pointPositions, this.speedLimit);

  factory Street.fromFeature(Map<String, dynamic> feature) {
    final List<LatLng> points = [];
    final List<dynamic> coordinates = feature['geometry']['coordinates'];
    final String? maxSpeed = feature['properties']['maxspeed'];
    
    for (var point in coordinates) {
      // Coordinates are the other way around.
      points.add(LatLng(point[1], point[0]));
    }

    return Street(
      feature['properties']['name'],
      points,
      maxSpeed != null ? int.parse(maxSpeed) : null
    );
  }
}

class StreetPoint {
  final LatLng position;
  final Street street;

  StreetPoint(this.position, this.street);
}