import 'package:candle_dash/model.dart';
import 'package:candle_dash/widgets/cluster/info_footer.dart';
import 'package:flutter/material.dart';
import 'package:candle_dash/widgets/cluster/power_bar.dart';
import 'package:candle_dash/widgets/cluster/speedometer.dart';
import 'package:property_change_notifier/property_change_notifier.dart';

class Cluster extends StatelessWidget {
  const Cluster({  Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PropertyChangeConsumer<AppModel, String>(
      properties: const ['drawer'],
      builder: (context, model, properties) {
        return AnimatedPadding(
          duration: const Duration(milliseconds: 300),
          curve: Curves.fastOutSlowIn,
          padding: model?.clusterPadding ?? EdgeInsets.zero,
          child: Column(
            children: const [
              PowerBar(),
              Speedometer(),
              InfoFooter(),
              SizedBox(height: 25)
            ],
          ),
        );
      }
    );
  }
}