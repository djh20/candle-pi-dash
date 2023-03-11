import 'package:candle_dash/model.dart';
import 'package:candle_dash/themes.dart';
import 'package:candle_dash/widgets/cluster/metric_display.dart';
import 'package:candle_dash/widgets/dilate_transition.dart';
import 'package:flutter/material.dart';
import 'package:property_change_notifier/property_change_notifier.dart';
import 'dart:math';

class ChargingCluster extends StatelessWidget {
  const ChargingCluster({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PropertyChangeConsumer<AppModel, String>(
      properties: const ['drawer'],
      builder: (context, model, properties) {
        final bool drawerOpen = model?.drawerOpen ?? false;

        return Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 1000),
                reverseDuration: const Duration(milliseconds: 50),
                switchInCurve: Curves.fastOutSlowIn,
                switchOutCurve: Curves.fastOutSlowIn,
                transitionBuilder: (child, animation) => 
                  DilateTransition(child: child, animation: animation),
                child: !drawerOpen ? const LargeInfoDisplay() : const SmallInfoDisplay(),
              ),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Opacity(
                      opacity: 0.2,
                      child: Image.asset(
                        "assets/renders/leaf/charging.png",
                      ),
                    ),
                    const AspectRatio(
                      aspectRatio: 32 / 11, // Aspect ratio of image
                      child: BatteryBar()
                    ),
                  ]
                ),
              ),
            ]
          ),
        );
      }
    );
  }
}

class BatteryBar extends StatelessWidget {
  const BatteryBar({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PropertyChangeConsumer<AppModel, String>(
      properties: const ['soc'],
      builder: (context, model, properties) {
        final double socPercent = model?.vehicle.metrics['soc']?.value ?? 0;

        return SizedBox(
          width: double.infinity,
          child: Align(
            alignment: const Alignment(0.16, 0.6),
            child: FractionallySizedBox(
              widthFactor: 0.36,
              heightFactor: 0.15,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: socPercent/100,
                  child: Container(
                    decoration: BoxDecoration(
                      color: chargeColor,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              ),
            ),
          )
        );
      }
    );
  }
}

class SmallInfoDisplay extends StatelessWidget {
  const SmallInfoDisplay({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        ChargeIcon(size: 60),
        BatteryInfo(),
      ]
    );
  }
}

class LargeInfoDisplay extends StatelessWidget {
  const LargeInfoDisplay({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: 0.9,
      child: SizedBox(
        height: 115,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: const [
            BatteryInfo(),
            ChargeIcon(),
            ChargeInfo()
          ],
        ),
      ),
    );
  }
}

class BatteryInfo extends StatelessWidget {
  const BatteryInfo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PropertyChangeConsumer<AppModel, String>(
      properties: const ['soc', 'range'],
      builder: (context, model, properties) {
        final int range = model?.vehicle.metrics['range']?.value ?? 0;
        final double socPercent = model?.vehicle.metrics['soc']?.value ?? 0;
        
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${socPercent.floor()}%",
              style: const TextStyle(fontSize: 65, fontWeight: FontWeight.bold),
            ),
            Text(
              "$range km",
              style: const TextStyle(fontSize: 32),
            ),
          ]
        );
      }
    );
  }
}

class ChargeInfo extends StatelessWidget {
  const ChargeInfo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PropertyChangeConsumer<AppModel, String>(
      properties: const [
        'motor_power', 
        'remaining_charge_time', 
        'soc',
        'charge_status'
      ],
      builder: (context, model, properties) {
        final double powerOutput = model?.vehicle.metrics['motor_power']?.value ?? 0;
        final double powerInput = max(-powerOutput, 0);
        final double socPercent = model?.vehicle.metrics['soc']?.value ?? 0;
        final int chargeStatus = model?.vehicle.metrics['charge_status']?.value ?? 0;

        final Duration chargeTime = Duration(
          minutes: model?.vehicle.metrics['remaining_charge_time']?.value ?? 0
        );

        bool chargeFinished = (chargeStatus == 2);
        bool chargeAlmostFinished = (socPercent >= 90) && (chargeStatus == 1);
        String chargeTimeText = "";

        if (chargeTime.inMinutes > 0) {
          if (chargeTime.inHours > 0) {
            chargeTimeText += "${chargeTime.inHours}h ";
          }

          chargeTimeText += "${chargeTime.inMinutes % 60}m";
        } else {
          chargeTimeText = "TBD";
        }
        
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!chargeFinished) Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: MetricDisplay(
                name: "Charge Power",
                value: "${powerInput.round()} kW",
              ),
            ),

            if (!chargeAlmostFinished && !chargeFinished) MetricDisplay(
              name: "Time Remaining",
              value: chargeTimeText,
            ), 

            if (chargeAlmostFinished) ... const [
              SizedBox(height: 6),
              Opacity(
                opacity: 0.8,
                child: Text(
                  "Almost Fully Charged",
                  style: TextStyle(
                    fontSize: 26
                  )
                ),
              ),
              SizedBox(height: 4),
              Opacity(
                opacity: 0.6,
                child: Text(
                  "Battery may not reach 100%",
                  style: TextStyle(
                    fontSize: 16
                  )
                ),
              ),
            ],

            if (chargeFinished) const Text(
              "Charging Complete",
              style: TextStyle(
                fontSize: 26
              )
            ),
          ],
        );
      }
    );
  }
}

class ChargeIcon extends StatelessWidget {
  final double size;

  const ChargeIcon({
    Key? key,
    this.size = 100
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PropertyChangeConsumer<AppModel, String>(
      properties: const ['charge_status'],
      builder: (context, model, properties) {
        final bool charging = model?.vehicle.metrics['charge_status']?.value == 1;

        return Icon(
          Icons.bolt_rounded, 
          size: size,
          color: charging ? chargeColor : Colors.grey
        );
      }
    );
  }
}