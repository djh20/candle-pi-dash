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
        'fan_speed',
        'eco',
        'drawer',
        'gear'
      ],
      builder: (context, model, properties) {
        final bool connected = model?.vehicle.connected ?? false;
        final bool eco = model?.vehicle.metrics['eco']?.value ?? false;
        final bool drawerOpen = model?.drawerOpen ?? false;
        final int gear = model?.vehicle.metrics['gear']?.value ?? 0;
        final bool parked = (gear == 0);

        final int fanSpeed = model?.vehicle.metrics['fan_speed']?.value ?? 0;
        final int fanSpeedPercent = ((fanSpeed / 7) * 100).round();

        return AnimatedOpacity(
          opacity: connected ? 1 : 0,
          duration: const Duration(milliseconds: 250),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedPadding(
                padding: EdgeInsets.fromLTRB(8, parked ? 8 : 22, 8, 8),
                duration: const Duration(milliseconds: 500),
                curve: Curves.fastOutSlowIn,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StatusIcon(
                      icon: Icons.eco_rounded,
                      active: eco,
                      text: "ECO",
                      color: Colors.green,
                      compact: drawerOpen
                    ),
                    StatusIcon(
                      icon: Icons.air_rounded,
                      active: fanSpeed > 0,
                      text: "$fanSpeedPercent%",
                      compact: drawerOpen
                    ),
                  ]
                ),
              ),
              
              AnimatedPadding(
                padding: EdgeInsets.only(
                  top: !drawerOpen ? 23 : 8,
                ),
                duration: const Duration(milliseconds: 300),
                curve: Curves.fastOutSlowIn,
                child: AnimatedScale(
                  scale: !drawerOpen ? 1 : 0.7,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.fastOutSlowIn,
                  alignment: Alignment.topRight,
                  child: SpeedLimitSign(
                    visible: 
                      model?.vehicle.displayedSpeedLimit != null && 
                      (model?.vehicle.displayedSpeedLimitAge ?? 0) <= 3 &&
                      !parked,
                    speedLimit: model?.vehicle.displayedSpeedLimit ?? 0
                  ),
                )
              )
              
            ],
          )
        );
      }
    );
  }
}