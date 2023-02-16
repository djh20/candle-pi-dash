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
      icon: Icons.air_rounded,
      sound: "info.mp3"
    ),
    Alert(
      id: "low_range", 
      title: "Low range",
      subtitle: "10km remaining",
      icon: Icons.battery_alert_rounded,
      sound: "critical.mp3",
      duration: const Duration(seconds: 10)
    ),
    Alert(
      id: "speeding",
      title: "Slow down!",
      subtitle: "Exceeding detected speed limit",
      icon: Icons.speed_rounded,
      sound: "critical.mp3",
      duration: const Duration(seconds: 5),
      repeatable: true
    ),
    Alert(
      id: "experimental",
      title: "Experimental version",
      subtitle: "Expect bugs & crashes",
      icon: Icons.bug_report,
      duration: const Duration(seconds: 5)
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

  int? lastSpeedLimitChangeTime;
  int noSpeedLimitCounter = 0;

  int? speedingStartTime;
  bool speedingAlertsEnabled = true;
  
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

    if (!alert.repeatable) shownAlerts.add(alert);
    
    messenger?.showSnackBar(
      SnackBar(
        padding: const EdgeInsets.all(10),
        /*shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(100)
          )
        ),*/
        //margin: const EdgeInsets.all(8),
        behavior: SnackBarBehavior.fixed,
        duration: alert.duration,
        onVisible: () {
          if (alert.sound != null) {
            audioPlayer.play(alert.sound!);
          }
        },
        content: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              alert.icon,
              size: 34,
              color: theme.scaffoldBackgroundColor
            ),
            const SizedBox(width: 6),
            Text(
              alert.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold
              )
            ),
            const SizedBox(width: 20),
            Text(
              alert.subtitle,
              style: const TextStyle(
                fontSize: 18,
              ),
            ),
          ],
        )
      )
    );
  }

  void updateMap(LatLng newPosition, double newRotation) async {
    /// This logic is a bit weird, but it's to prevent the map from doing a
    /// large rotation when not necessary. For example:
    /// 
    /// If the map is rotating from 20 to 320 degrees, instead of doing a
    /// 300 degree rotation from 20 to 230, it will do a 50 degree rotation
    /// from 20 to -30. This stops the map from flipping back and forth when
    /// the rotation crosses over 360 degrees.
    newRotation = -newRotation;
    
    final normalMag = (newRotation - mapRotation).abs();
    final crossPositiveMag = (360 + newRotation) - mapRotation;
    final crossNegativeMag = mapRotation + (360 - newRotation);

    if (crossPositiveMag < normalMag) {
      newRotation = 360 + newRotation;
    } else if (crossNegativeMag < normalMag) {
      newRotation = -crossNegativeMag;
    }

    /// Only update map position if the drawer is open and on the correct
    /// page. This stops the issue where the controller errors because the
    /// map widget doesn't exist.
    final bool gpsLocked = vehicle.getMetricBool("gps_lock");

    if (drawerOpen && gpsLocked && vPage == 0) {
      mapLatTween = Tween<double>(
        begin: mapPosition.latitude, end: newPosition.latitude
      );
      mapLngTween = Tween<double>(
        begin: mapPosition.longitude, end: newPosition.longitude
      );

      mapRotTween = Tween<double>(
          begin: mapRotation, end: newRotation
      );

      //print('$mapRotation -> $newRotation ($tweenRotation)');
      
      mapAnim =
        CurvedAnimation(parent: mapAnimController, curve: Curves.linear);
      mapAnimController.reset();
      mapAnimController.forward();
    }

    final oldSpeedLimit = vehicle.speedLimit;
    final speedLimit = await getSpeedLimit(newPosition, vehicle.speedLimit);

    final int now = DateTime.now().millisecondsSinceEpoch;

    // Set lastSpeedLimitChangeTime if the speed limit has changed
    if (speedLimit != oldSpeedLimit) {
      lastSpeedLimitChangeTime = now;
    }

    if (speedLimit != null) {
      vehicle.displayedSpeedLimit = speedLimit;
      vehicle.displayedSpeedLimitAge = 0;
    } else {
      vehicle.displayedSpeedLimitAge++;
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

    final vehicleSpeed = vehicle.getMetricDouble("speed");

    final int totalSamples = max(vehicleSpeed.round() ~/ 4, 1);
    
    const int gapBetweenSamples = 10;

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

    final double vehicleBearing = vehicle.bearingDeg;
    final double vehicleBearingInverted = clampAngle(vehicleBearing + 180);

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
      
      WayNode? closestNode = getClosestWayNode(samplePos, ways);
      if (closestNode != null && closestNode.way.geometry.length > 1) {
        final Way way = closestNode.way;
        late LatLng otherNodePos;
        
        if (closestNode.index < way.geometry.length - 1) {
          otherNodePos = way.geometry[closestNode.index + 1];
        } else {
          otherNodePos = way.geometry[closestNode.index - 1];
        }

        final double wayBearing = 
          getBearingBetweenPoints(closestNode.pos, otherNodePos).degrees;

        final double bearingDiff = min(
          (vehicleBearing - wayBearing).abs(),
          (vehicleBearingInverted - wayBearing).abs()
        );

        if (bearingDiff <= 20) {
          final String wayName = way.tags["name"] ?? "";
          final int speedLimit = int.parse(way.tags["maxspeed"]!);
          debugPrint('${offset}m: $samplePos ($speedLimit) ($wayName) ($bearingDiff)');
          speedLimits.add(speedLimit);
        }
      }
    }

    debugPrint(speedLimits.toString());
    
    if (speedLimits.isNotEmpty) {
      final int furthestSpeedLimit = speedLimits.last;

      // Find the total occurences of the speed limit from the end of the array (in a row).
      final int occurrences = speedLimits.reversed.takeWhile(
        (speedLimit) => speedLimit == furthestSpeedLimit
      ).length;

      final int minOccurrences = (speedLimits.length / 2).round();

      if (occurrences >= minOccurrences) {
        final speedDiff = vehicleSpeed - furthestSpeedLimit;

        // Assume the speed limit is invalid if the vehicle is travelling significantly
        // faster than it. The purpose of this is to reduce the amount of incorrect speed 
        // limit detections, as someone will likely not be travelling 30 km/h faster than
        // the actual speed limit.
        if (speedDiff >= 30) return null;
        
        return furthestSpeedLimit;

      } else {
        return currentSpeedLimit;
      }
    }

    return null;
  }


  WayNode? getClosestWayNode(LatLng pos, List<Way> ways, {double maxDistance = 40}) {
    WayNode? closestWayNode;
    double closestWayNodeDistance = maxDistance;
    
    for (var way in ways) {
      for (int i = 0; i < way.geometry.length; i++) {
        LatLng nodePos = way.geometry[i];
        final distance = getDistance(pos, nodePos);

        if (distance < closestWayNodeDistance) {
          closestWayNode = WayNode(way, nodePos, i);
          closestWayNodeDistance = distance;
        }
      }
    }

    return closestWayNode;
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
    final tags = Map<String, String?>.from(parsedJson["tags"]);

    final List<dynamic> rawGeometry = parsedJson["geometry"];
    final List<LatLng> geometry = 
      rawGeometry.map((e) => LatLng(e["lat"], e["lon"])).toList();

    return Way(geometry, tags);
  }
}

class WayNode {
  final Way way;
  final LatLng pos;
  final int index;

  WayNode(this.way, this.pos, this.index);
}

class Alert {
  final String id;
  final IconData icon;
  final String title;
  final String subtitle;
  final String? sound;
  final bool repeatable;
  final Duration duration;
  
  Alert({
    required this.id,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.sound,
    this.repeatable = false,
    this.duration = const Duration(seconds: 7)
  });
}
