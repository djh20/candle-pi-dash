import 'package:candle_dash/elm.dart';
import 'package:candle_dash/model.dart';
import 'package:flutter/material.dart';
import 'package:property_change_notifier/property_change_notifier.dart';

class ConnectingCluster extends StatelessWidget {
  const ConnectingCluster({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PropertyChangeConsumer<AppModel, String>(
      properties: const ['connecting'],
      builder: (context, model, properties) {
        if (model?.vehicle.connecting == true) {
          return const CircularProgressIndicator();
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              OutlinedButton(
                onPressed: () => model?.vehicle.connect(ElmConnectionType.bluetooth), 
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.bluetooth, size: 64),
                      SizedBox(width: 10),
                      Text("Bluetooth", style: TextStyle(fontSize: 32))
                    ],
                  ),
                )
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () => model?.vehicle.connect(ElmConnectionType.wifi),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.wifi, size: 64),
                      SizedBox(width: 20),
                      Text("WiFi", style: TextStyle(fontSize: 32))
                    ],
                  ),
                )
              ),
              /*
              Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.bluetooth, size: 38),
                  Transform.scale(
                    scale: 1.3,
                    child: const CircularProgressIndicator(strokeWidth: 2)
                  )
                ],
              ),
              const SizedBox(width: 16),
              const Text(
                "Connecting...", 
                style: TextStyle(fontSize: 32)
              ),
              */
            ],
          ),
        );
      }
    );
  }
}