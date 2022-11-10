import 'dart:math';
import 'package:flutter/material.dart';

Point<int> worldToTile(double lat, double lng, double zoom) {
  int x = ((lng+180)/360*pow(2,zoom)).floor();
  int y = ((1-log(tan(lat*pi/180) + 1/cos(lat*pi/180))/pi)/2 *pow(2,zoom)).floor();

  return Point<int>(x, y);
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
