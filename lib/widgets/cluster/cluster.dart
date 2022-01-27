import 'package:dash_delta/model.dart';
import 'package:dash_delta/widgets/cluster/info_footer.dart';
import 'package:flutter/material.dart';
import 'package:dash_delta/widgets/cluster/power_bar.dart';
import 'package:dash_delta/widgets/cluster/speedometer.dart';
import 'package:property_change_notifier/property_change_notifier.dart';

class Cluster extends StatelessWidget {
  const Cluster({  Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    //final model = context.watch<AppModel>();
    
    //final bool powered = model.vehicle.getMetric("powered") == 1 ? true : false;
    //final int gear = model.vehicle.getMetric("gear");
    //final int speed = model.vehicle.getMetric("rear_speed").round();
    //final double power = model.vehicle.getMetric("power") / 1;

    /*
    final model = PropertyChangeProvider.of<AppModel, String>(
      context,
      properties: []
      );
      */

    //print('cluster');
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

/*
Text(
  "47",
  style: TextStyle(fontSize: 170)
)
*/