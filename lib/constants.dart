
class Constants {
  // This class is not meant to be instantiated or extended; this constructor prevents instantiation and extension.
  Constants._();

  static const String prodIp = "192.168.1.1";
  static const String devIp = "10.1.2.57";

  static const List<String> gearSymbols = ['P', 'P', '', 'N', ''];
  static const List<String> gearLabels = ['', '', 'REVERSE', '', 'km/h'];

  static const double cardContentHeight = 288.0;
}