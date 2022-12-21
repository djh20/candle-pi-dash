import 'package:candle_dash/model.dart';
import 'package:candle_dash/widgets/cluster/charging_cluster.dart';
import 'package:candle_dash/widgets/cluster/connecting_cluster.dart';
import 'package:candle_dash/widgets/dilate_transition.dart';
import 'package:candle_dash/widgets/drawer/drawer.dart';
import 'package:flutter/material.dart';
import 'package:candle_dash/widgets/cluster/driving_cluster.dart';
import 'package:candle_dash/widgets/roof.dart';
import 'package:property_change_notifier/property_change_notifier.dart';

class Dash extends StatelessWidget {
  const Dash({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PropertyChangeConsumer<AppModel, String>(
      properties: const ['connected', 'plugged_in', 'drawer'],
      builder: (context, model, properties) {
        final bool connected = (model?.vehicle.connected == true);
        final bool pluggedIn = model?.vehicle.getMetricBool("plugged_in") ?? false;
        
        return Stack(
          fit: StackFit.expand,
          children: [
            AnimatedPadding(
              duration: const Duration(milliseconds: 300),
              curve: Curves.fastOutSlowIn,
              padding: model?.clusterPadding ?? EdgeInsets.zero,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 1000),
                reverseDuration: const Duration(milliseconds: 200),
                switchInCurve: Curves.fastOutSlowIn,
                switchOutCurve: Curves.fastOutSlowIn,
                transitionBuilder: (child, animation) => 
                  DilateTransition(child: child, animation: animation),
                child: connected ? 
                  (pluggedIn ? const ChargingCluster() : const DrivingCluster())
                  : const ConnectingCluster()
              )
            ),
            const SideDrawer(),
            const Roof(),
          ],
        );
      }
    );
  }
}