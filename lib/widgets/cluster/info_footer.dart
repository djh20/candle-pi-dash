import 'package:candle_dash/model.dart';
import 'package:candle_dash/widgets/cluster/large_unit_text.dart';
import 'package:candle_dash/widgets/cluster/metric_display.dart';
import 'package:flutter/material.dart';
import 'package:property_change_notifier/property_change_notifier.dart';

import 'linear_arc_indicator.dart';

class InfoFooter extends StatelessWidget {
  const InfoFooter({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    Color contrasting = theme.textTheme.bodyText1?.color ?? Colors.black;

    return PropertyChangeConsumer<AppModel, String>(
      properties: const [
        'range', 
        'soc_percent', 
        'time', 
        'gps_trip_distance',
        'gps_locked',
        'charging'
      ],
      builder: (context, model, properties) {
        final int range = model?.vehicle.getMetric('range') ?? 0;
        final double soc = model?.vehicle.getMetricDouble('soc_percent') ?? 0;
        final bool charging = model?.vehicle.getMetricBool('charging') ?? false;
        
        final String distance = 
          ((model?.vehicle.getMetricDouble('gps_trip_distance') ?? 0) / 1000)
          .toStringAsFixed(1);

        final bool gpsLocked = model?.vehicle.getMetricBool('gps_locked') ?? false;

        final IconData batteryIcon = 
          (charging) ? Icons.battery_charging_full : 
          (range >= 10) ? Icons.battery_full : Icons.battery_alert;
        
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                LargeUnitText(
                  model?.time ?? '', 
                  unit: model?.timeUnit ?? ''
                ),
                const SizedBox(width: 30),
                LargeUnitText(range.toString(), unit: 'km'),
                LinearArcIndicator(
                  value: soc, 
                  min: 0,
                  max: 100,
                  icon: batteryIcon
                )
              ],
            ),
            
            const SizedBox(height: 5),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 500),
              style: TextStyle(
                color: gpsLocked ? contrasting : theme.hintColor
              ),
              child: MetricDisplay(
                name: 'Travelled',
                value: '${distance}km',
              ),
            ),
            MetricDisplay(
              name: 'Charge',
              value: '$soc%',
            )
          ],
        );
      }
    );
  }
}