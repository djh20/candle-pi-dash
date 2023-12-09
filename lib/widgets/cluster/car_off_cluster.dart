import 'package:candle_dash/model.dart';
import 'package:candle_dash/widgets/cluster/metric_display.dart';
import 'package:candle_dash/widgets/cluster/speedometer.dart';
import 'package:candle_dash/widgets/cluster/trip_info.dart';
import 'package:flutter/material.dart';
import 'package:property_change_notifier/property_change_notifier.dart';

class CarOffCluster extends StatelessWidget {
  const CarOffCluster({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PropertyChangeConsumer<AppModel, String>(
      properties: const [
        'gps'
      ],
      builder: (context, model, properties) {
        ThemeData theme = Theme.of(context);

        double gpsDistance = model?.vehicle.gpsDistance ?? 0;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 30),
          child: Column(
            children: [
              Expanded(
                child: Opacity(
                  opacity: 0.2,
                  child: Image.asset(
                    "assets/renders/leaf/charging.png",
                  ),
                ),
              ),
              /*
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    "VEHICLE OFFLINE", 
                    style: TextStyle(
                      fontSize: 24, 
                      fontWeight: FontWeight.bold
                    )
                  ),
                ],
              ),
              */
              //const Speedometer(),
              const SizedBox(height: 20),
              if (gpsDistance > 0) const TripInfo(),
              const SizedBox(height: 20),
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        "CONNECTED", 
                        style: TextStyle(
                          fontSize: 26, 
                          fontWeight: FontWeight.bold
                        )
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        "PRESS", 
                        style: TextStyle(fontSize: 20)
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(
                          Icons.power_settings_new,
                          size: 22
                        ),
                      ),
                      Text(
                        "TO START", 
                        style: TextStyle(fontSize: 20)
                      ),
                    ],
                  ),
                ]
              )
            ],
          ),
        );
      }
    );

  }
}