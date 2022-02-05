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
      properties: const ['clusterOffset'],
      builder: (context, model, properties) {
        return AnimatedSlide(
          duration: const Duration(milliseconds: 300),
          curve: Curves.fastOutSlowIn,
          offset: model?.clusterOffset ?? const Offset(0,0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Speedometer(),
              PowerBar(),
              InfoFooter(),
              SizedBox(height: 15)
              //Text(power.toString())
            ],
          ),
        );
      }
    );
  }
}