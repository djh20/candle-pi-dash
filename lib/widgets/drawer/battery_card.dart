import 'package:candle_dash/constants.dart';
import 'package:candle_dash/model.dart';
import 'package:candle_dash/themes.dart';
import 'package:candle_dash/widgets/vertical_battery_meter.dart';
import 'package:candle_dash/widgets/cluster/metric_display.dart';
import 'package:candle_dash/widgets/typography/unit_text.dart';
import 'package:flutter/material.dart';
import 'package:property_change_notifier/property_change_notifier.dart';

class BatteryCardContent extends StatefulWidget {
  const BatteryCardContent({ Key? key }) : super(key: key);

  @override
  State<BatteryCardContent> createState() => _BatteryCardContentState();
}

class _BatteryCardContentState extends State<BatteryCardContent> {
  bool showChargeStats = false;

  @override
  Widget build(BuildContext context) {
    return PropertyChangeConsumer<AppModel, String>(
      properties: const [
        'powered',
        'battery_power',
        'battery_temp',
        'battery_capacity'
        'soh',
        'quick_charges',
        'slow_charges'
      ],
      builder: (context, model, properties) {
        final bool powered = model?.vehicle.getMetricBool('powered') ?? false;

        /*if (!powered) {
          return const CardAlert(text: "Stats unavailable");
        }*/

        final int soh = model?.vehicle.getMetric('soh') ?? 0;

        final double batteryCapacity =
          model?.vehicle.getMetricDouble('battery_capacity') ?? 0;

        final double batteryTemp = 
          model?.vehicle.getMetricDouble('battery_temp') ?? 0;

        final double power = 
          model?.vehicle.getMetricDouble('battery_power') ?? 0;

        final int quickCharges = model?.vehicle.getMetric('quick_charges') ?? 0;
        final int slowCharges = model?.vehicle.getMetric('slow_charges') ?? 0;

        //final double batteryValue = mapToAlpha(batteryTemp, 23.0, 32.0);

        return SizedBox(
          height: Constants.cardContentHeight,
          child: Column(
            children: [
              Expanded(
                child: powered ? 
                  Padding(
                    child: BatteryDiagram(
                      power: power,
                      batteryTemp: batteryTemp
                    ),
                    padding: const EdgeInsets.only(top: 10, left: 30, right: 30, bottom: 20)
                  ) :
                  const Center(
                    child: Text(
                      "Live stats unavailable",
                      style: TextStyle(fontSize: 20)
                    )
                  ),
              ),
              GestureDetector(
                onTap: () => setState(() => showChargeStats = !showChargeStats),
                behavior: HitTestBehavior.translucent,
                child: Column(
                  children: [
                    if (!showChargeStats) MetricDisplay(name: "Health", value: "$soh%"),
                    if (!showChargeStats) MetricDisplay(name: "Capacity", value: "${batteryCapacity.round()} kWh"),
                    if (showChargeStats) MetricDisplay(name: "Quick", value: quickCharges.toString()),
                    if (showChargeStats) MetricDisplay(name: "Slow", value: slowCharges.toString())
                  ],
                )
              ),
              const SizedBox(height: 5)
            ],
          ),
        );
      }
    );
  }
}

class BatteryDiagram extends StatelessWidget {
  final double power;
  final double batteryTemp;

  const BatteryDiagram({
    Key? key,
    required this.power,
    required this.batteryTemp
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      fit: StackFit.expand,
      children: [
        VerticalBatteryMeter(
          color: chargeColor.withOpacity(0.8)
        ),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              UnitText(
                power.round().toString(),
                unit: 'kW',
                scale: 1.5
              ),
              const SizedBox(height: 10),
              UnitText(
                batteryTemp.round().toString(),
                unit: '°C'
              )
            ],
          )
        )
      ],
    );
  }
}