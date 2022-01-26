import 'package:flutter/material.dart';
import 'package:dash_delta/widgets/cluster/cluster.dart';
import 'package:dash_delta/widgets/roof.dart';

class Dash extends StatelessWidget {
  //final Vehicle vehicle;

  const Dash({ 
    Key? key,
    //required this.vehicle
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    //final model = context.watch<AppModel>();

    //final bool powered = model.vehicle.getMetric("powered") == 1 ? true : false;
    //final int gear = model.vehicle.getMetric("gear");
    //final int speed = model.vehicle.getMetric("rear_speed").round();
    //final double power = model.vehicle.getMetric("power") / 1;

    //print("dash");

    return Padding(
      padding: const EdgeInsets.all(11.5),
      child: Stack(
        fit: StackFit.expand,
        children: const [
          Cluster(),
          Roof()
        ],
      )
    );
  }
}