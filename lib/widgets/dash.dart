import 'package:dash_delta/widgets/drawer/drawer.dart';
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