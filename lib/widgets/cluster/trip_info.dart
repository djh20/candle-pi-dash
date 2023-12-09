

import 'package:candle_dash/model.dart';
import 'package:candle_dash/widgets/cluster/metric_display.dart';
import 'package:flutter/material.dart';
import 'package:property_change_notifier/property_change_notifier.dart';

class TripInfo extends StatelessWidget {
  const TripInfo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PropertyChangeConsumer<AppModel, String>(
      properties: const [
        'range',
        'range_at_last_charge',
        'gps'
      ],
      builder: (context, model, properties) {
        final int range = model?.vehicle.getMetric('range');
        final int rangeAtLastCharge = model?.vehicle.getMetric('range_at_last_charge');
        final double gpsDistance = model?.vehicle.gpsDistance ?? 0;
        final String gpsDistanceFormatted = gpsDistance.toStringAsFixed(1);

        final double idealRange = rangeAtLastCharge - gpsDistance;
        final int rangeVariation = (range - idealRange).round();

        final String rangeVariationText = 
          (rangeVariation == 0 || rangeAtLastCharge == 0) ? "Perfect" :
          (rangeVariation > 0) ? "+$rangeVariation km" : "$rangeVariation km";

        return Column(
          children: [
            MetricDisplay(
              name: 'Travelled',
              value: '$gpsDistanceFormatted km',
            ),
            MetricDisplay(
              name: 'Efficiency',
              value: rangeVariationText,
              valueColor: (rangeVariation >= 0) ? Colors.green : Colors.red,
            ),
          ],
        );
      }
    );
  }
}