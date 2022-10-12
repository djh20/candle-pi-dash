import 'package:candle_dash/widgets/speed_limit_sign.dart';
import 'package:candle_dash/widgets/status_icon.dart';
import 'package:flutter/material.dart';
import 'package:property_change_notifier/property_change_notifier.dart';
import 'package:candle_dash/model.dart';

class Roof extends StatelessWidget {
  const Roof({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PropertyChangeConsumer<AppModel, String>(
      properties: const [
        'connected', 
        'speedLimit', 
        'cc_fan_speed',
        'eco',
        'drawer',
        'gear',
        'gps_locked'
      ],
      builder: (context, model, properties) {
        final connected = model?.vehicle.connected ?? false;
        final int fanSpeed = model?.vehicle.getMetric('cc_fan_speed') ?? 0;
        final bool eco = model?.vehicle.getMetricBool('eco') ?? false;
        final bool gpsLocked = model?.vehicle.getMetricBool('gps_locked') ?? false;
        final bool drawerOpen = model?.drawerOpen ?? false;
        //final bool powered = model?.vehicle.getMetricBool('powered') ?? false;
        final int gear = model?.vehicle.getMetric('gear') ?? 0;
        final bool parked = (gear <= 1);

        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedPadding(
                padding: EdgeInsets.only(top: parked ? 0 : 13),
                duration: const Duration(milliseconds: 500),
                curve: Curves.fastOutSlowIn,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StatusIcon(
                      icon: Icons.wifi,
                      active: connected
                    ),
                    const SizedBox(height: 7),
                    StatusIcon(
                      icon: Icons.air,
                      active: fanSpeed > 0,
                      activeText: fanSpeed.toString(),
                      compact: drawerOpen
                    ),
                    const SizedBox(height: 7),
                    StatusIcon(
                      icon: Icons.eco,
                      active: eco,
                      activeText: "ECO",
                      color: Colors.green,
                      compact: drawerOpen
                    ),
                  ]
                ),
              ),
              
              AnimatedPadding(
                padding: EdgeInsets.only(top: !drawerOpen ? 13 : 0),
                duration: const Duration(milliseconds: 300),
                curve: Curves.fastOutSlowIn,
                child: AnimatedScale(
                  scale: !drawerOpen ? 1 : 0.7,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.fastOutSlowIn,
                  alignment: Alignment.topRight,
                  child: SpeedLimitSign(
                    visible: model?.vehicle.speedLimit != null && !parked && gpsLocked,
                    speedLimit: model?.vehicle.lastSpeedLimit ?? 0
                  ),
                )
              )
              
            ],
          ),
        );
      }
    );
  }
}