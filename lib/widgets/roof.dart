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
        'cc_status',
        'eco'
      ],
      builder: (context, model, properties) {
        final connected = model?.vehicle.connected ?? false;
        final bool ccStatus = model?.vehicle.getMetricBool('cc_status') ?? false;
        final bool eco = model?.vehicle.getMetricBool('eco') ?? false;

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StatusIcon(
                    icon: Icons.wifi,
                    active: connected
                  ),
                  const SizedBox(height: 7),
                  StatusIcon(
                    icon: Icons.air,
                    active: ccStatus,
                  ),
                  const SizedBox(height: 7),
                  StatusIcon(
                    icon: Icons.eco,
                    active: eco
                  ),
                ]
              ),
              
              SpeedLimitSign(
                visible: model?.vehicle.speedLimit != null,
                speedLimit: model?.vehicle.lastSpeedLimit ?? 0
              )
            ],
          ),
        );
      }
    );
  }
}