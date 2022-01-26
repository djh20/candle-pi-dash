import 'package:property_change_notifier/property_change_notifier.dart';
import 'package:dash_delta/vehicle.dart';

class AppModel extends PropertyChangeNotifier<String> {
  late Vehicle vehicle;

  AppModel() {
    vehicle = Vehicle(this);
  }

  void notify(String? property) => notifyListeners(property);
}