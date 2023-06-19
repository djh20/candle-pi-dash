import 'dart:async';

import 'package:cron/cron.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:property_change_notifier/property_change_notifier.dart';
import 'package:candle_dash/widgets/routes/home.dart';
import 'package:candle_dash/model.dart';
import 'package:screen_state/screen_state.dart';

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
  late ScheduledTask fullscreenTask;

  late Screen screen;
  late StreamSubscription<ScreenStateEvent> screenSubscription;
  
  @override
  void initState() {
    super.initState();
    model.init();
    imageCache.clear();

    fullscreenTask = cron.schedule(Schedule.parse('* * * * * *'), model.fullscreen);
    timeTask = cron.schedule(Schedule.parse('*/1 * * * *'), model.updateTime);
    themeTask = cron.schedule(Schedule.parse('*/5 * * * * *'), model.updateTheme);

    screen = Screen();
    try {
      screenSubscription = screen.screenStateStream!.listen(onScreenData);
    } on ScreenStateException catch (exception) {
      print(exception);
    }

    //model.updateTime();
    //model.updateTheme();
    
    //model.vehicle.connect();
  }

  void onScreenData(ScreenStateEvent event) {
    if (event == ScreenStateEvent.SCREEN_OFF) {
      model.vehicle.disconnect();
    } else if (event == ScreenStateEvent.SCREEN_ON) {
      model.vehicle.connect();
    }
  }

  @override
  Widget build(BuildContext context) {
    model.fullscreen();
    model.updateTheme();
    model.updateTime();
    return PropertyChangeProvider<AppModel, String>( //ChangeNotifierProvider
      value: model,
      child: PropertyChangeConsumer<AppModel, String>(
        properties: const ['theme'],
        builder: (context, model, properties) {
          return MaterialApp(
            theme: model?.theme,
            initialRoute: '/',
            home: Scaffold(
              key: model?.scaffoldKey,
              resizeToAvoidBottomInset: false,
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
    fullscreenTask.cancel();
    timeTask.cancel();
    themeTask.cancel();
    super.dispose();
  }
}
