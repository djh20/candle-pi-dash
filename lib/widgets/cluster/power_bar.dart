import 'package:candle_dash/model.dart';
import 'package:flutter/material.dart';
import 'package:property_change_notifier/property_change_notifier.dart';

const double inMaxPower = 30;
const double outMaxPower = 80;
const double deadZone = 0.015;

class PowerBar extends StatelessWidget {
  const PowerBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color contrastingColor = theme.textTheme.bodyText1?.color ?? Colors.black;
    final Color outColor = contrastingColor;
    const Color inColor = Color.fromRGBO(30, 212, 51, 1);

    return PropertyChangeConsumer<AppModel, String>(
      properties: const ['power_output', 'powered', 'gear'],
      builder: (context, model, properties) {
        final double power = model?.vehicle.getMetricDouble('power_output') ?? 0.0;
        final int gear = model?.vehicle.getMetric('gear') ?? 0;

        // Vehicle must be in drive or reverse to show power.
        final bool visible = (gear == 4 || gear == 2);
        
        return AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: const Duration(milliseconds: 250),
          child: Row(
            children: [
              PowerBarSegment(
                alignment: Alignment.centerRight,
                widthFactor: ((-power / inMaxPower) - deadZone).clamp(0, 1),
                color: inColor,
                notches: (inMaxPower ~/ 10)
              ),

              const SizedBox(width: 1),

              PowerBarSegment(
                alignment: Alignment.centerLeft,
                widthFactor: ((power / outMaxPower) - deadZone).clamp(0, 1),
                color: outColor,
                notches: (outMaxPower ~/ 10)
              )
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
  final int notches;
  final bool hideFirstNotch;
  
  const PowerBarSegment({
    Key? key,
    required this.alignment,
    required this.widthFactor,
    required this.color,
    this.notches = 0,
    this.hideFirstNotch = false
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Expanded(
      child: Stack(
        alignment: alignment,
        children: [
          FractionallySizedBox(
            widthFactor: widthFactor,
            child: Container(
              color: color,
              height: 5
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(notches, (i) => Container(
              height: 8,
              width: 2,
              color: (i == 0 && hideFirstNotch) ? null : theme.hintColor
            )),
          ),
        ],
      ),
    );
  }
}