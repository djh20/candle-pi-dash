import 'package:candle_dash/widgets/drawer/drawer.dart';
import 'package:flutter/material.dart';
import 'package:candle_dash/widgets/cluster/cluster.dart';
import 'package:candle_dash/widgets/roof.dart';

class Dash extends StatelessWidget {
  //final Vehicle vehicle;

  const Dash({ 
    Key? key,
    //required this.vehicle
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: const [
        Padding(
          padding: EdgeInsets.all(11.5),
          child: Cluster(),
        ),
        SideDrawer(),
        Roof(),
      ],
    );
  }
}