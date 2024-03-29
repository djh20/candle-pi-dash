import 'package:cron/cron.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:property_change_notifier/property_change_notifier.dart';
import 'package:candle_dash/widgets/routes/home.dart';
import 'package:candle_dash/model.dart';

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

  final cron = Cron();
  late ScheduledTask themeTask;
  late ScheduledTask timeTask;
  
  @override
  void initState() {
    super.initState();
    model.init();
    imageCache.clear();

    // Update time on every minute.
    timeTask = cron.schedule(Schedule.parse('*/1 * * * *'), model.updateTime);
    themeTask = cron.schedule(Schedule.parse('*/5 * * * * *'), model.updateTheme);

    //model.updateTime();
    //model.updateTheme();
    
    model.vehicle.connect();
  }

  @override
  Widget build(BuildContext context) {
    model.updateTheme();
    model.updateTime();
    return PropertyChangeProvider<AppModel, String>( //ChangeNotifierProvider
      value: model,
      child: PropertyChangeConsumer<AppModel, String>(
        properties: const ['theme'],
        builder: (context, model, properties) {
          // Hides the Android status and control bar.
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
          
          return MaterialApp(
            theme: model?.theme,
            initialRoute: '/',
            home: Scaffold(
              key: model?.scaffoldKey,
              body: const HomePage()
            ),
            debugShowCheckedModeBanner: false
          );
        },
      )
    );
  }

  @override
  void dispose() {
    timeTask.cancel();
    themeTask.cancel();
    super.dispose();
  }
}
