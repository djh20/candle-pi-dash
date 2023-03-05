
class Constants {
  // This class is not meant to be instantiated or extended; this constructor prevents instantiation and extension.
  Constants._();

  static const String defaultHost = "192.168.1.1";

  static const List<String> gearSymbols = ['P', 'P', 'R', 'N', ''];
  //static const List<String> gearLabels = ['', '', '', '', 'km/h'];

  static const double drawerWidth = 260.0;
  static const double cardContentHeight = 288.0;

  static const double earthRadius = 6371e3;
  static const int mapZoom = 15;

  static const int speedingAlertTime = 15 * 1000; // 15 seconds
  static const int speedingAlertThreshold = 10; // 10 km/h over speed limit
}