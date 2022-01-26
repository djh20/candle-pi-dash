import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:property_change_notifier/property_change_notifier.dart';
import 'package:dash_delta/themes.dart';
import 'package:dash_delta/widgets/routes/home.dart';
import 'package:dash_delta/model.dart';

void main() {
  runApp(const App());
}

class App extends StatefulWidget {
  const App({Key? key}) : super(key: key);

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  AppModel model = AppModel();

  @override
  void initState() {
    super.initState();
    model.vehicle.connect();
  }

  @override
  Widget build(BuildContext context) {
    //print('main');

    // Hides the Android status and control bar.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);

    return PropertyChangeProvider<AppModel, String>( //ChangeNotifierProvider
      value: model,
      child: MaterialApp(
        theme: Themes.light,
        initialRoute: '/',
        routes: {
          '/': (context) => const HomePage()
        },
        debugShowCheckedModeBanner: false
      ),
    );
  }
}
