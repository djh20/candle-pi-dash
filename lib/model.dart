import 'dart:convert';
import 'dart:math';

import 'package:candle_dash/constants.dart';
import 'package:candle_dash/themes.dart';
import 'package:candle_dash/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:property_change_notifier/property_change_notifier.dart';
import 'package:candle_dash/vehicle.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:light/light.dart';

class AppModel extends PropertyChangeNotifier<String> {
  late PackageInfo packageInfo;
  late Vehicle vehicle;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Alert> alerts = [
    Alert(
      id: "cc_on", 
      title: "Range is reduced",
      subtitle: "Climate control is consuming power",
      icon: Icons.air,
      sound: "info.mp3"
    ),
    Alert(
      id: "low_range", 
      title: "Low range",
      subtitle: "Vehicle range is at 10km",
      icon: Icons.battery_alert,
      sound: "critical.mp3"
    ),
    Alert(
      id: "neutral", 
      title: "Vehicle is in neutral",
      subtitle: "Switch to drive or reverse",
      icon: Icons.drive_eta,
      sound: "info.mp3"
    ),
  ];

  bool alertsEnabled = false;
  List<Alert> shownAlerts = [];

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
  
  AppModel() {
    vehicle = Vehicle(this);
  }

  void init() async {
    packageInfo = await PackageInfo.fromPlatform();
    
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

  ScaffoldMessengerState? get messenger {
    final BuildContext? context = scaffoldKey.currentContext;
    if (context == null) return null;

    return ScaffoldMessenger.of(context);
  }

  void showAlert(String id) {
    if (!alertsEnabled) return;
    
    final Alert? alert = alerts.firstWhere((a) => a.id == id);
    if (alert == null) return;

    // Return if the alert has already been shown.
    if (shownAlerts.contains(alert)) return;
    shownAlerts.add(alert);
    
    messenger?.showSnackBar(
      SnackBar(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(
          bottom: 45,
          left: 120,
          right: 120
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 7),
        onVisible: () => audioPlayer.play(alert.sound),
        content: Row(
          children: [
            Icon(
              alert.icon,
              size: 40,
              color: theme.scaffoldBackgroundColor
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  alert.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold
                  )
                ),
                Text(
                  alert.subtitle,
                  style: const TextStyle(
                    fontSize: 18
                  ),
                ),
              ],
            )
          ],
        )
      )
    );
  }

  void updateMap(LatLng newPosition, double newRotation) async {
    /// Only update map position if the drawer is open and on the correct
    /// page. This stops the issue where the controller errors because the
    /// map widget doesn't exist.
    final bool gpsLocked = vehicle.getMetricBool("gps_locked");

    if (drawerOpen && gpsLocked && vPage == 0) {
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

    final speedLimit = await getSpeedLimit(newPosition, vehicle.speedLimit);

    if (speedLimit != null) {
      vehicle.lastSpeedLimit = speedLimit;
    }
    
    vehicle.speedLimit = speedLimit;

    notify("speedLimit"); 

    mapPosition = newPosition;
    mapRotation = newRotation;
  }

  Future<int?> getSpeedLimit(LatLng position, int? currentSpeedLimit) async {
    const R = Constants.earthRadius;

    final latRad = position.latitudeInRad;  
    final lngRad = position.longitudeInRad;

    final vehicleSpeed = vehicle.getMetricDouble("wheel_speed");

    final int totalSamples = max(vehicleSpeed.round() ~/ 4, 1);
    //const double initialPointOffset = 50;
    
    const int gapBetweenSamples = 10;

    //final List<int> offsets = [gap*1, gap*2, gap*3, gap*4];
    //debugPrint("$offsets");

    //final List<StreetPoint> points = []; 
    final List<Way> ways = [];
    final List<int> speedLimits = [];

    const int maxTileDistance = 1; // Total: 9 tiles.
    
    final originTilePos = 
      worldToTile(position.latitude, position.longitude, Constants.mapZoom.toDouble());

    for (int xOffset = -maxTileDistance; xOffset <= maxTileDistance; xOffset++) {
      for (int yOffset = -maxTileDistance; yOffset <= maxTileDistance; yOffset++) {
        final tilePos = Point<int>(
          originTilePos.x + xOffset, 
          originTilePos.y + yOffset
        );

        final String tileWaysFileName = 
          "${Constants.mapZoom}-${tilePos.x}-${tilePos.y}.json";

        String? tileWaysData;

        try {
          tileWaysData = 
            await rootBundle.loadString("assets/generated/map/$tileWaysFileName");

        } catch (err) {
          debugPrint(err.toString());
        }

        if (tileWaysData == null) continue;

        final List<dynamic> tileWaysJson = await jsonDecode(tileWaysData);
        final List<Way> tileWays = tileWaysJson.map((e) => Way.fromJson(e)).toList();

        ways.addAll(tileWays);
      }
    }

    // Get the closest way for each offset.
    for (var i = 0; i < totalSamples; i++) {
      final offset = gapBetweenSamples * (i + 1);

      final sampleLatRad = asin( 
        sin(latRad) * cos(offset/R) + 
        cos(latRad) * sin(offset/R)* cos(vehicle.bearingRad)
      );

      final sampleLngRad = 
        lngRad + atan2(
          sin(vehicle.bearingRad) * sin(offset/R)* cos(latRad), 
          cos(offset/R) - sin(latRad)* sin(sampleLatRad)
        );

      var samplePos = LatLng(
        sampleLatRad * (180/pi),
        sampleLngRad * (180/pi)
      );
      
      Way? closestWay = getClosestWay(samplePos, ways);

      if (closestWay != null) { // && closestPoint.street.speedLimit != null
        final String wayName = closestWay.tags["name"] ?? "";
        final int speedLimit = int.parse(closestWay.tags["maxspeed"]!);
        debugPrint('${offset}m: $samplePos ($speedLimit) ($wayName)');
        speedLimits.add(speedLimit);
      } else {
        debugPrint('${offset}m: $samplePos');
      }
    }

    //speedLimits.clear();
    debugPrint(speedLimits.toString());
    
    if (speedLimits.isNotEmpty) {
      final int furthestSpeedLimit = speedLimits.last;

      final int occurrences = speedLimits.where(
        (speedLimit) => speedLimit == furthestSpeedLimit
      ).length;

      final int minOccurrences = (speedLimits.length / 2).round();

      if (occurrences >= minOccurrences) {
        final speedDiff = vehicleSpeed - speedLimits[0];

        // Assume the speed limit is invalid if the vehicle is travelling significantly
        // faster than it. The purpose of this is to reduce the amount of incorrect speed 
        // limit detections, as someone will likely not be travelling 30 km/h faster than
        // the actual speed limit.
        if (speedDiff >= 30) return null;

        return furthestSpeedLimit;
      }

      return currentSpeedLimit;
    }
 
    return null;
  }


  Way? getClosestWay(LatLng pos, List<Way> ways, {double maxDistance = 80}) {
    Way? closestWay;
    double closestWayDistance = maxDistance;
    //LatLng? closestWayPos;
    
    for (var way in ways) {
      for (var nodePos in way.geometry) {
        final distance = getDistance(pos, nodePos);

        if (distance < closestWayDistance) {
          closestWay = way;
          closestWayDistance = distance;
        }
      }
    }

    return closestWay;
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
    //debugPrint(_luxValue.toString());
    if (_autoTheme) {
      if (_luxValue >= 150) {
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


class Way {
  final List<LatLng> geometry;
  final Map<String, String?> tags;

  Way(this.geometry, this.tags);

  factory Way.fromJson(dynamic parsedJson) {
    //final int id = parsedJson["id"];
    final tags = Map<String, String?>.from(parsedJson["tags"]);

    final List<dynamic> rawGeometry = parsedJson["geometry"];
    final List<LatLng> geometry = 
      rawGeometry.map((e) => LatLng(e["lat"], e["lon"])).toList();

    return Way(geometry, tags);
  }
}

/*
class StreetPoint {
  final LatLng position;
  final Street street;

  StreetPoint(this.position, this.street);
}
*/

class Alert {
  final String id;
  final IconData icon;
  final String title;
  final String subtitle;
  final String sound;
  
  Alert({
    required this.id,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.sound = 'alert.mp3'
  });
}
