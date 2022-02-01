import 'package:dash_delta/constants.dart';
import 'package:dash_delta/model.dart';
import 'package:dash_delta/widgets/typography/unit_text.dart';
import 'package:flutter/material.dart';
import 'package:property_change_notifier/property_change_notifier.dart';

class InsightsCardContent extends StatelessWidget {
  const InsightsCardContent({ Key? key }) : super(key: key);

  Color getLerpedColor(double t, {
      Color a = Colors.green,
      Color b = Colors.red
  }) {
    final HSVColor hsvColor = HSVColor.lerp(
      HSVColor.fromColor(a), 
      HSVColor.fromColor(b), 
      t
    ) ?? HSVColor.fromColor(a);

    return hsvColor.toColor();
  }

  double map(double value, double min, double max) {
    double diff = max-min;

    double alpha = ((value-min)/diff).clamp(0.0, 1.0);
    return alpha;
  }

  @override
  Widget build(BuildContext context) {
    return PropertyChangeConsumer<AppModel, String>(
      properties: const [
        'wheel_speed',
        'motor_temp',
        'inverter_temp',
        'power_output'
      ],
      builder: (context, model, properties) {
        final double leftSpeed = 
          model?.vehicle.getMetricDouble('wheel_speed', 1) ?? 0;

        final double rightSpeed = 
          model?.vehicle.getMetricDouble('wheel_speed', 2) ?? 0;

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

        final double inverterValue = map(inverterTemp, 23.0, 32.0);
        final double batteryValue = map(batteryTemp, 23.0, 32.0);
        final double motorValue = map(motorTemp, 23.0, 32.0);

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
                color: getLerpedColor(inverterValue),
                colorBlendMode: BlendMode.modulate,
              ),
              Image.asset(
                "assets/insights/battery.png",
                color: getLerpedColor(batteryValue),
                colorBlendMode: BlendMode.modulate,
              ),
              Image.asset(
                "assets/insights/motor.png",
                color: getLerpedColor(motorValue),
                colorBlendMode: BlendMode.modulate,
              ),
              Image.asset(
                "assets/insights/left-wheels.png",
                color: getLerpedColor(leftWheelsValue),
                colorBlendMode: BlendMode.modulate,
              ),
              Image.asset(
                "assets/insights/right-wheels.png",
                color: getLerpedColor(rightWheelsValue),
                colorBlendMode: BlendMode.modulate,
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  UnitText(batteryTemp.round().toString(), '°C'),
                  const SizedBox(height: 5),
                  UnitText(power.round().toString(), 'kW'),
                ],
              ),
              //UnitText(batteryTemp.round().toString(), '°C'),
              /*
              Positioned(
                top: 0,
                left: 80,
                child: UnitText(motorTemp.round().toString(), '°C'),
              ),
              Positioned(
                top: 57,
                left: 70,
                child: UnitText(inverterTemp.round().toString(), '°C'),
              )
              */
            ]
          ),
        );
      }
    );
  }
}