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
      properties: const ['wheel_speed', 'powered', 'gear', 'eco', 'drawer'],
      builder: (context, model, properties) {
        final double leftSpeed = model?.vehicle.getMetricDouble('wheel_speed', 1) ?? 0;
        final double rightSpeed = model?.vehicle.getMetricDouble('wheel_speed', 2) ?? 0;

        /// We average the left and right speed because the senors go down to
        /// 1 km/h, whereas the rear speed only goes down to 3 km/h.
        final int speed = ((leftSpeed + rightSpeed)/2).round();
        
        final bool powered = model?.vehicle.getMetricBool('powered') ?? false;
        final bool drawerOpen = model?.drawerOpen ?? false;
        final int gear = model?.vehicle.getMetric('gear');

        final String gearSymbol = Constants.gearSymbols[gear];
        final String text = gearSymbol == '' ? speed.toString() : gearSymbol;

        final Color textColor = powered ? 
          (theme.textTheme.bodyText1?.color ?? Colors.black) 
          : theme.hintColor;

        final bool powerBarVisible = (gear > 1);

        return AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            curve: Curves.fastOutSlowIn,
            style: TextStyle(
              color: powered ? textColor : theme.hintColor,
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