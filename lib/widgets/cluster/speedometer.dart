import 'package:flutter/material.dart';
import 'package:property_change_notifier/property_change_notifier.dart';
import 'package:dash_delta/constants.dart';
import 'package:dash_delta/model.dart';

class Speedometer extends StatelessWidget {
  const Speedometer({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);

    return PropertyChangeConsumer<AppModel, String>(
      properties: const ['wheel_speed', 'powered', 'gear', 'eco'],
      builder: (context, model, properties) {
        //final int speed = model?.vehicle.getMetricDouble('wheel_speed').round() ?? 0;

        final double leftSpeed = model?.vehicle.getMetricDouble('wheel_speed', 1) ?? 0;
        final double rightSpeed = model?.vehicle.getMetricDouble('wheel_speed', 2) ?? 0;

        /// We average the left and right speed because the senors go down to
        /// 1 km/h, whereas the rear speed only goes down to 3 km/h.
        final int speed = ((leftSpeed + rightSpeed)/2).round();
        
        final bool powered = model?.vehicle.getMetricBool('powered') ?? false;
        final bool eco = model?.vehicle.getMetricBool('eco') ?? false;
        final int gear = model?.vehicle.getMetric('gear');

        final String gearSymbol = Constants.gearSymbols[gear];
        final String gearLabel = Constants.gearLabels[gear];

        final String text = gearSymbol == '' ? speed.toString() : gearSymbol;
        final Color textColor =
          (powered ? 
          (!eco ? theme.textTheme.bodyText1?.color : Colors.green) :
          theme.hintColor) ?? Colors.black;

        return Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 500),
            style: TextStyle(
              color: powered ? textColor : textColor.withAlpha(20)
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 153,
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontSize: 180, 
                      height: 0.98,
                      fontWeight: FontWeight.w700
                    ),
                  ),
                ),
                const SizedBox(
                  height: 5
                ),
                Text(
                  gearLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1,
                    fontWeight: FontWeight.w600,
                    //color: textColor.withOpacity(0.3)
                  )
                ),
              ],
            )
          )
        );

      }
    );
  }
}