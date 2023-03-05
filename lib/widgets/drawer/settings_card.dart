import 'package:candle_dash/constants.dart';
import 'package:candle_dash/model.dart';
import 'package:candle_dash/themes.dart';
import 'package:flutter/material.dart';
import 'package:property_change_notifier/property_change_notifier.dart';

class SettingsCardContent extends StatelessWidget {
  const SettingsCardContent({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final buttonStyle = ElevatedButton.styleFrom(
      minimumSize: const Size.fromHeight(40),
      elevation: 0
    );

    return PropertyChangeConsumer<AppModel, String>(
      properties: const ['speedingAlertsEnabled'],
      builder: (context, model, properties) {
        return Column(
          children: [
            ElevatedButton(
              child: const Text("LIGHT THEME"),
              style: buttonStyle,
              onPressed: () {
                model?.setAutoTheme(false);
                model?.setTheme(Themes.light);
              },
            ),
            ElevatedButton(
              child: const Text("DARK THEME"),
              style: buttonStyle,
              onPressed: () {
                model?.setAutoTheme(false);
                model?.setTheme(Themes.dark);
              },
            ),
            ElevatedButton(
              child: const Text("AUTO THEME"),
              style: buttonStyle,
              onPressed: () => model?.setAutoTheme(true),
            ),

            model?.speedingAlertsEnabled == false ? 
              ElevatedButton(
                child: const Text("ENABLE SPEEDING ALERTS"),
                style: buttonStyle,
                onPressed: () {
                  model?.speedingAlertsEnabled = true;
                  model?.notify("speedingAlertsEnabled");
                }
              ) :
              ElevatedButton(
                child: const Text("DISABLE SPEEDING ALERTS"),
                style: buttonStyle.copyWith(
                  backgroundColor: MaterialStateProperty.all<Color>(Colors.red)
                ),
                onPressed: () {
                  model?.speedingAlertsEnabled = false;
                  model?.notify("speedingAlertsEnabled");
                }
              ),
            
            ElevatedButton(
              child: const Text("DISCONNECT"),
              style: buttonStyle,
              onPressed: () => model?.vehicle.close(),
            ),

            const SizedBox(height: 5),
            Text("v${model?.packageInfo.version ?? ""}")
          ],
        );
      }
    );
  }
}