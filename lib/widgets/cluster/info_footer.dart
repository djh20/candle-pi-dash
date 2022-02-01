import 'package:dash_delta/model.dart';
import 'package:dash_delta/widgets/cluster/large_unit_text.dart';
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
        
        final double distance = 
          (model?.vehicle.getMetricDouble('gps_trip_distance') ?? 0) 
          / 1000; // Convert m to km

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
            const SizedBox(height: 10),
            
            Text(
              'Battery Charge: $soc%',
              style: TextStyle(
                fontSize: 18,
                color: contrasting.withOpacity(0.8)
              ),
            ),
            const SizedBox(height: 5),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 500),
              style: TextStyle(
                fontSize: 18,
                color: gpsLocked ? contrasting.withOpacity(0.8) : contrasting.withOpacity(0.2)
              ),
              child: Text('Travelled: ${distance.toStringAsFixed(1)}km'),
            ),
            
          ],
        );
      }
    );
  }
}