import 'dart:math';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

Point<int> worldToTile(double lat, double lng, double zoom) {
  int x = ((lng+180)/360*pow(2,zoom)).floor();
  int y = ((1-log(tan(lat*pi/180) + 1/cos(lat*pi/180))/pi)/2 *pow(2,zoom)).floor();

  return Point<int>(x, y);
}

Bearing getBearingBetweenPoints(LatLng a, LatLng b) {
  final double teta1 = a.latitudeInRad;
  final double teta2 = b.latitudeInRad;
  final double delta2 = degToRadian(b.longitude - a.longitude);
  
  final double y = sin(delta2) * cos(teta2);
  final double x = cos(teta1)*sin(teta2) - sin(teta1)*cos(teta2)*cos(delta2);

  final double bearingRad = atan2(y, x);
  final double bearingDeg = clampAngle(radianToDeg(bearingRad));
  
  return Bearing(bearingDeg, bearingRad);
}

double clampAngle(double angle) {
  return ( (angle + 360) % 360 );
}

Color lerpColor(double a, {
  Color from = Colors.green,
  Color to = Colors.red
}) {
  final HSVColor hsvColor = HSVColor.lerp(
    HSVColor.fromColor(from), 
    HSVColor.fromColor(to), 
    a
  ) ?? HSVColor.fromColor(from);

  return hsvColor.toColor();
}

double mapToAlpha(double value, double min, double max) {
  double diff = max-min;

  double alpha = ((value-min)/diff).clamp(0.0, 1.0);
  return alpha;
}

int getTimeElapsed(int time) {
  final int now = DateTime.now().millisecondsSinceEpoch;
  return (now - time);
}

String intToHex(int integer, int? minLength) {
  String hex = integer.toRadixString(16).toUpperCase();
  if (minLength != null) hex = hex.padLeft(minLength, '0');
  return hex;
}

class Bearing {
  final double degrees;
  final double radians;

  Bearing(this.degrees, this.radians);
}