

import 'package:candle_dash/model.dart';
import 'package:candle_dash/themes.dart';
import 'package:flutter/material.dart';
import 'package:property_change_notifier/property_change_notifier.dart';

class VerticalBatteryMeter extends StatelessWidget {
  final Color color;
  final double width;

  const VerticalBatteryMeter({
    Key? key,
    this.color = chargeColor,
    this.width = double.infinity,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PropertyChangeConsumer<AppModel, String>(
      properties: const ['soc_percent'],
      builder: (context, model, properties) {
        final double socPercent = model?.vehicle.getMetricDouble('soc_percent') ?? 0;
        
        return SizedBox(
          width: width,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.5),
              borderRadius: BorderRadius.circular(5),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.bottomCenter,
              heightFactor: socPercent/100,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ),
        );
      }
    );
  }
}