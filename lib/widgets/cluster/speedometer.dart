import 'package:candle_dash/utils.dart';
import 'package:flutter/material.dart';
import 'package:property_change_notifier/property_change_notifier.dart';
import 'package:candle_dash/constants.dart';
import 'package:candle_dash/model.dart';

class Speedometer extends StatelessWidget {
  const Speedometer({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);

    return PropertyChangeConsumer<AppModel, String>(
      properties: const [
        'speed',
        'powered',
        'gear',
        'drawer',
        'speedLimit'],
      builder: (context, model, properties) {
        final double speed = model?.vehicle.getMetricDouble('speed') ?? 0;
        final double? speedLimit = model?.vehicle.speedLimit?.toDouble();
        
        final bool powered = model?.vehicle.getMetricBool('powered') ?? false;
        final bool drawerOpen = model?.drawerOpen ?? false;
        final int gear = model?.vehicle.getMetric('gear');

        final String gearSymbol = Constants.gearSymbols[gear];
        final String text = gearSymbol == '' ? speed.round().toString() : gearSymbol;

        Color speedColor = powered ? 
          (theme.textTheme.bodyText1?.color ?? Colors.black) 
          : theme.hintColor;

        if (
          speedLimit != null &&
          model?.speedingAlertsEnabled == true &&
          model?.lastSpeedLimitChangeTime != null &&
          getTimeElapsed(model!.lastSpeedLimitChangeTime!) >= 5000
        ) {
          /*
          if (speed > speedLimit + Constants.speedingAlertThreshold) {
            speedColor = Colors.red;
          }
          */

          final double speedingFactor = mapToAlpha(
            speed, 
            speedLimit + (Constants.speedingAlertThreshold - 2), 
            speedLimit + (Constants.speedingAlertThreshold + 2)
          );

          speedColor = lerpColor(
            speedingFactor, 
            from: speedColor, 
            to: Colors.red
          );
        }

        final bool powerBarVisible = (gear > 1);

        return AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            curve: Curves.fastOutSlowIn,
            style: TextStyle(
              color: powered ? speedColor : theme.hintColor,
              fontSize: !drawerOpen ? 180 : 155
            ),
            child: AnimatedPadding(
              padding: EdgeInsets.only(top: powerBarVisible ? 13 : 0),
              duration: const Duration(milliseconds: 500),
              curve: Curves.fastOutSlowIn,
              child: Column(
                children: [
                  const SizedBox(height: 70),
                  Text(
                    text,
                    style: const TextStyle(
                      height: 0.45,
                      fontWeight: FontWeight.w700
                    ),
                  ),
                ],
              ),
            )
          
        );
      }
    );
  }
}