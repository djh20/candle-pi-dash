
class Constants {
  // This class is not meant to be instantiated or extended; this constructor prevents instantiation and extension.
  Constants._();

  static const String prodIp = "192.168.1.1";
  static const String devIp = "10.1.2.57";

  static const List<String> gearSymbols = ['P', 'P', 'R', 'N', ''];
  //static const List<String> gearLabels = ['', '', '', '', 'km/h'];

  static const double drawerWidth = 270.0;
  static const double cardContentHeight = 288.0;

  static const double earthRadius = 6371e3;
}