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
                        "assets/charging/leaf.png",
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
      properties: const ['soc_percent'],
      builder: (context, model, properties) {
        final double socPercent = model?.vehicle.getMetricDouble('soc_percent') ?? 0;

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
                child: Stack(
                  children: [
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: socPercent/100,
                      child: Container(
                        decoration: BoxDecoration(
                          color: chargeColor,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                    Align(
                      alignment: const Alignment(0.8, 0),
                      child: Container(
                        height: double.infinity,
                        width: 2,
                        color: Colors.white.withOpacity(0.8)
                      )
                    ),
                    const Center(
                      child: Text(
                        "Limit: ~90%",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold
                        )
                      )
                    )
                  ]
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
      properties: const ['soc_percent', 'range'],
      builder: (context, model, properties) {
        final int range = model?.vehicle.getMetric("range");
        final double socPercent = model?.vehicle.getMetricDouble('soc_percent') ?? 0;
        
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${socPercent.round()}%",
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
      properties: const ['power_output', 'remaining_charge_time'],
      builder: (context, model, properties) {
        final double powerOutput = model?.vehicle.getMetricDouble('power_output') ?? 0;
        final double powerInput = max(-powerOutput, 0);

        final Duration chargeTime = Duration(
          minutes: model?.vehicle.getMetric("remaining_charge_time")
        );

        bool almostCharged = (chargeTime.inMinutes < 5) && (powerInput < 1);
        String chargeTimeText = "";

        if (chargeTime.inMinutes > 0) {
          if (chargeTime.inHours > 0) {
            chargeTimeText += "${chargeTime.inHours}h ";
          }

          chargeTimeText += "${chargeTime.inMinutes % 60}m";
        } else {
          chargeTimeText = "???";
        }
        
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: !almostCharged ? [
            MetricDisplay(
              name: "Charge Power",
              value: "${powerInput.round()} kW",
            ),
            const SizedBox(height: 5),
            MetricDisplay(
              name: "Time Remaining",
              value: chargeTimeText,
            )
          ] : [
            const Text(
              "Charging Almost Complete",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold
              )
            )
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
    return Icon(
      Icons.bolt_rounded, 
      size: size,
      color: chargeColor
    );
  }
}