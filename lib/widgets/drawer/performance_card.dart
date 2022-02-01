import 'package:dash_delta/model.dart';
import 'package:flutter/material.dart';
import 'package:property_change_notifier/property_change_notifier.dart';

class PerformanceCardContent extends StatelessWidget {
  const PerformanceCardContent({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PropertyChangeConsumer<AppModel, String>(
      properties: const ['pTracking'],
      builder: (context, model, properties) {
        final bool tracking = model?.vehicle.pTracking.tracking ?? false;
        final String buttonText = !tracking ? "START TRACKING" : "STOP TRACKING";

        List<Widget> items = [];

        if (model != null) {
          for (var milestone in model.vehicle.pTracking.milestones) {
            //'0 - ${milestone.speed}: ${milestone.time}s
            items.add(
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Text(
                      '0 - ${milestone.speed}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold
                      )
                    ),
                    if (milestone.reached) Text(
                      '  ${milestone.time}s',
                      style: const TextStyle(
                        fontSize: 20
                      )
                    ),
                  ]
                ),
              ),
            );
          }
        }
        
        return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 190,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: items
                ),
              ),

              ElevatedButton(
                child: Text(buttonText),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(80),
                  elevation: 0,
                  primary: tracking ? Colors.red : null
                ),
                onPressed: () => 
                  model?.vehicle.pTracking.setTracking(!tracking),
              )
              /*
              Text(
                "CAR MUST BE STOPPED",
                style: TextStyle(
                  
                )
              )
              */
            
            ],
        );
      }
    );
  }
}