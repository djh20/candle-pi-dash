import 'package:candle_dash/model.dart';
import 'package:candle_dash/themes.dart';
import 'package:flutter/material.dart';
import 'package:property_change_notifier/property_change_notifier.dart';

const double inMaxPower = 20;
const double outMaxPower = 80;
const double deadZone = 1;

class PowerBar extends StatelessWidget {
  const PowerBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color contrastingColor = theme.textTheme.bodyText1?.color ?? Colors.black;
    final Color outColor = contrastingColor;
    const Color inColor = chargeColor;

    return PropertyChangeConsumer<AppModel, String>(
      properties: const ['battery_power', 'powered', 'gear'],
      builder: (context, model, properties) {
        double power = model?.vehicle.getMetricDouble('battery_power') ?? 0.0;
        final int gear = model?.vehicle.getMetric('gear') ?? 0;

        // Vehicle must not be in park to show power.
        final bool visible = (gear > 0);
        
        return AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: const Duration(milliseconds: 250),
          child: Row(
            children: [
              PowerBarSegment(
                alignment: Alignment.centerRight,
                widthFactor: (((-power - deadZone) / inMaxPower)).clamp(0, 1),
                color: inColor
              ),
              const SizedBox(width: 4),
              PowerBarSegment(
                alignment: Alignment.centerLeft,
                widthFactor: (((power - deadZone) / outMaxPower)).clamp(0, 1),
                color: outColor
              ),
            ],
          ),
        );
      }
    );
  }
}

class PowerBarSegment extends StatelessWidget {
  final Alignment alignment;
  final double widthFactor;
  final Color color;
  
  const PowerBarSegment({
    Key? key,
    required this.alignment,
    required this.widthFactor,
    required this.color
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10)
        ),
        clipBehavior: Clip.antiAlias,
        child: AnimatedFractionallySizedBox(
          widthFactor: widthFactor,
          alignment: alignment,
          duration: const Duration(milliseconds: 100),
          child: Container(
            color: color,
            height: 7
          ),
        ),
      ),
    );
  }
}