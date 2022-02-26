import 'package:candle_dash/widgets/speed_limit_sign.dart';
import 'package:flutter/material.dart';
import 'package:property_change_notifier/property_change_notifier.dart';
import 'package:candle_dash/model.dart';

class Roof extends StatelessWidget {
  const Roof({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PropertyChangeConsumer<AppModel, String>(
      properties: const ['connected', 'speedLimit', 'drawer'],
      builder: (context, model, properties) {
        final connected = model?.vehicle.connected ?? false;
        return Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /*
              IconButton(
                icon: Icon(connected ? Icons.wifi : Icons.wifi_off),
                iconSize: 15,
                visualDensity: VisualDensity.compact,
                onPressed: () => {},
              )*/
              Icon(
                connected ? Icons.wifi : Icons.wifi_off,
                size: 15
              ),
              
              SpeedLimitSign(
                visible: model?.vehicle.speedLimit != null,
                speedLimit: model?.vehicle.lastSpeedLimit ?? 0
                /*streetName: 
                  (model?.drawerOpen == false) ? 
                  model?.vehicle.street?.name : null*/
              )
            ],
          ),
        );
      }
    );
  }
}