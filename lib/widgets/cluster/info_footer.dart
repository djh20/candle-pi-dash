import 'package:candle_dash/model.dart';
import 'package:candle_dash/widgets/cluster/metric_display.dart';
import 'package:candle_dash/widgets/typography/unit_text.dart';
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
        'range_at_last_charge'
        'soc_percent', 
        'time', 
        'gps_distance',
        'gps_locked'
      ],
      builder: (context, model, properties) {
        final int range = model?.vehicle.getMetric('range');
        final int rangeAtLastCharge = model?.vehicle.getMetric('range_at_last_charge');

        final double soc = model?.vehicle.getMetricDouble('soc_percent') ?? 0;
        
        final double gpsDistance = 
          (model?.vehicle.getMetricDouble('gps_distance') ?? 0) / 1000;

        final String gpsDistanceFormatted = gpsDistance.toStringAsFixed(1);

        final bool gpsLocked = model?.vehicle.getMetricBool('gps_locked') ?? false;

        final IconData batteryIcon = 
          (range > 10) ? Icons.battery_full_rounded : Icons.battery_alert_rounded;

        final double idealRange = rangeAtLastCharge - gpsDistance;
        final int rangeVariation = (range - idealRange).round();

        final String rangeVariationText = 
          (rangeVariation == 0 || rangeAtLastCharge == 0) ? "Perfect" :
          (rangeVariation > 0) ? "+$rangeVariation km" : "$rangeVariation km";
        
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                UnitText(
                  model?.time ?? '', 
                  unit: model?.timeUnit ?? ''
                ),
                const SizedBox(width: 30),
                UnitText(range.toString(), unit: 'km'),
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
                value: '$gpsDistanceFormatted km',
              ),
            ),
            MetricDisplay(
              name: 'Efficiency',
              value: rangeVariationText,
              valueColor: (rangeVariation >= 0) ? Colors.green : Colors.red,
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