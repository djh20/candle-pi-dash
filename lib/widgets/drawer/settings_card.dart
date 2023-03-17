import 'package:candle_dash/constants.dart';
import 'package:candle_dash/model.dart';
import 'package:candle_dash/themes.dart';
import 'package:flutter/material.dart';
import 'package:property_change_notifier/property_change_notifier.dart';

class SettingsCardContent extends StatelessWidget {
  const SettingsCardContent({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final buttonStyleOne = ElevatedButton.styleFrom(
      elevation: 0
    );

    final buttonStyleTwo = ElevatedButton.styleFrom(
      minimumSize: const Size.fromHeight(40),
      elevation: 0
    );

    return PropertyChangeConsumer<AppModel, String>(
      properties: const ['speedingAlertsEnabled', 'recording'],
      builder: (context, model, properties) {
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  child: const Text("LIGHT"),
                  style: buttonStyleOne,
                  onPressed: () {
                    model?.setAutoTheme(false);
                    model?.setTheme(Themes.light);
                  },
                ),
                ElevatedButton(
                  child: const Text("DARK"),
                  style: buttonStyleOne,
                  onPressed: () {
                    model?.setAutoTheme(false);
                    model?.setTheme(Themes.dark);
                  },
                ),
                ElevatedButton(
                  child: const Text("AUTO"),
                  style: buttonStyleOne,
                  onPressed: () => model?.setAutoTheme(true),
                ),
              ],
            ),

            model?.speedingAlertsEnabled == false ? 
              ElevatedButton(
                child: const Text("ENABLE SPEEDING ALERTS"),
                style: buttonStyleTwo,
                onPressed: () {
                  model?.speedingAlertsEnabled = true;
                  model?.notify("speedingAlertsEnabled");
                }
              ) :
              ElevatedButton(
                child: const Text("DISABLE SPEEDING ALERTS"),
                style: buttonStyleTwo.copyWith(
                  backgroundColor: MaterialStateProperty.all<Color>(Colors.red)
                ),
                onPressed: () {
                  model?.speedingAlertsEnabled = false;
                  model?.notify("speedingAlertsEnabled");
                }
              ),

            model?.vehicle.recording == false ? 
              ElevatedButton(
                child: const Text("START RECORDING"),
                style: buttonStyleTwo,
                onPressed: () => model?.vehicle.startRecording()
              ) :
              ElevatedButton(
                child: const Text("STOP RECORDING"),
                style: buttonStyleTwo.copyWith(
                  backgroundColor: MaterialStateProperty.all<Color>(Colors.red)
                ),
                onPressed: () => model?.vehicle.stopRecording()
              ),
            
            ElevatedButton(
              child: const Text("START DATA PLAYBACK"),
              style: buttonStyleTwo,
              onPressed: () => model?.vehicle.playbackData()
            ),

            ElevatedButton(
              child: const Text("DISCONNECT"),
              style: buttonStyleTwo,
              onPressed: () => model?.vehicle.disconnect(),
            ),

            const SizedBox(height: 5),
            Text("v${model?.packageInfo.version ?? ""}")
          ],
        );
      }
    );
  }
}