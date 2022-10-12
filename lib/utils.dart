import 'dart:math';

Point<int> worldToTile(double lat, double lng, double zoom) {
  int x = ((lng+180)/360*pow(2,zoom)).floor();
  int y = ((1-log(tan(lat*pi/180) + 1/cos(lat*pi/180))/pi)/2 *pow(2,zoom)).floor();

  return Point<int>(x, y);
}
