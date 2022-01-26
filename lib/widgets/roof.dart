import 'package:flutter/material.dart';
import 'package:property_change_notifier/property_change_notifier.dart';
import 'package:dash_delta/model.dart';

class Roof extends StatelessWidget {
  const Roof({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PropertyChangeConsumer<AppModel, String>(
      properties: const ['connection_status'],
      builder: (context, model, properties) {
        final connected = model?.vehicle.connected ?? false;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              icon: Icon(connected ? Icons.wifi : Icons.wifi_off),
              iconSize: 20,
              visualDensity: VisualDensity.compact,
              onPressed: () => {},
            )
          ],
        );
      }
    );
  }
}