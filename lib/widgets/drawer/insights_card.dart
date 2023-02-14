import 'package:candle_dash/constants.dart';
import 'package:candle_dash/model.dart';
import 'package:candle_dash/utils.dart';
import 'package:candle_dash/widgets/typography/unit_text.dart';
import 'package:flutter/material.dart';
import 'package:property_change_notifier/property_change_notifier.dart';

class InsightsCardContent extends StatelessWidget {
  const InsightsCardContent({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PropertyChangeConsumer<AppModel, String>(
      properties: const [
        'left_wheel_speed',
        'right_wheel_speed',
        'motor_temp',
        'inverter_temp',
        'power_output'
      ],
      builder: (context, model, properties) {
        final double leftSpeed = 
          model?.vehicle.getMetricDouble('left_wheel_speed') ?? 0;

        final double rightSpeed = 
          model?.vehicle.getMetricDouble('right_wheel_speed') ?? 0;

        final double inverterTemp = 
          model?.vehicle.getMetricDouble('inverter_temp') ?? 0;

        final double motorTemp = 
          model?.vehicle.getMetricDouble('motor_temp') ?? 0;

        final double batteryTemp = 
          model?.vehicle.getMetricDouble('battery_temp') ?? 0;

        final double power = 
          model?.vehicle.getMetricDouble('power_output') ?? 0;

        final double turnBias = (leftSpeed-rightSpeed)/3;

        final double leftWheelsValue = (-turnBias).clamp(0.0, 1.0);
        final double rightWheelsValue = (turnBias).clamp(0.0, 1.0);

        final double inverterValue = mapToAlpha(inverterTemp, 23.0, 32.0);
        final double batteryValue = mapToAlpha(batteryTemp, 23.0, 32.0);
        final double motorValue = mapToAlpha(motorTemp, 23.0, 32.0);

        return SizedBox(
          height: Constants.cardContentHeight,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: 0.1,
                child: Image.asset(
                  "assets/insights/chassis.png"
                ),
              ),
              Image.asset(
                "assets/insights/inverter.png",
                color: lerpColor(inverterValue),
                colorBlendMode: BlendMode.modulate,
              ),
              Image.asset(
                "assets/insights/battery.png",
                color: lerpColor(batteryValue),
                colorBlendMode: BlendMode.modulate,
              ),
              Image.asset(
                "assets/insights/motor.png",
                color: lerpColor(motorValue),
                colorBlendMode: BlendMode.modulate,
              ),
              Image.asset(
                "assets/insights/left-wheels.png",
                color: lerpColor(leftWheelsValue),
                colorBlendMode: BlendMode.modulate,
              ),
              Image.asset(
                "assets/insights/right-wheels.png",
                color: lerpColor(rightWheelsValue),
                colorBlendMode: BlendMode.modulate,
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  UnitText(
                    power.round().toString(),
                    unit: 'kW',
                    scale: 0.9
                  ),
                  const SizedBox(height: 5),
                  UnitText(
                    batteryTemp.round().toString(),
                    unit: '°C',
                    scale: 0.65
                  )
                ],
              ),
              Positioned(
                top: 19,
                left: 110,
                child: UnitText(
                  motorTemp.round().toString(),
                  unit: '°C',
                  scale: 0.4
                ),
              ),
              Positioned(
                top: 56,
                left: 106,
                child: UnitText(
                  inverterTemp.round().toString(),
                  unit: '°C',
                  scale: 0.4
                ),
              )
            ]
          ),
        );
      }
    );
  }
}