import 'package:flutter/material.dart';
import 'package:dash_delta/widgets/cluster/power_bar.dart';
import 'package:dash_delta/widgets/cluster/speedometer.dart';

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

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Speedometer(),
        PowerBar()
        //Text(power.toString())
      ],
    );
  }
}

/*
Text(
  "47",
  style: TextStyle(fontSize: 170)
)
*/