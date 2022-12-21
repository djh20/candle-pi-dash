import 'package:candle_dash/constants.dart';
import 'package:candle_dash/model.dart';
import 'package:candle_dash/widgets/cluster/metric_display.dart';
import 'package:flutter/material.dart';
import 'package:property_change_notifier/property_change_notifier.dart';

class MetricsCardContent extends StatelessWidget {
  const MetricsCardContent({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PropertyChangeConsumer<AppModel, String>(
      builder: (context, model, properties) {
        List<Widget> items = [];
        final metrics = model?.vehicle.metrics;

        if (metrics != null && metrics.isNotEmpty) {
          metrics.forEach((key, value) {
            items.add(
              MetricDisplay(
                name: key, 
                value: value.join(", ")
              )
            );
          });
        } else {
          items.add(const Text("No metrics available."));
        }

        return SizedBox(
          height: Constants.cardContentHeight,
          child: FittedBox(
            alignment: Alignment.topCenter,
            fit: BoxFit.scaleDown,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: items,
            ),
          )
        );

      }
    );
  }
}