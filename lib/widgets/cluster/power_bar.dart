import 'package:candle_dash/model.dart';
import 'package:flutter/material.dart';
import 'package:property_change_notifier/property_change_notifier.dart';

const double inMaxPower = 30;
const double outMaxPower = 85;
//const double deadZone = 0.015;

class PowerBar extends StatelessWidget {
  const PowerBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color contrastingColor = theme.textTheme.bodyText1?.color ?? Colors.black;
    final Color outColor = contrastingColor.withAlpha(200);
    const Color inColor = Color.fromRGBO(30, 212, 51, 1);

    return PropertyChangeConsumer<AppModel, String>(
      properties: const ['power_output', 'powered', 'gear'],
      builder: (context, model, properties) {
        double power = model?.vehicle.getMetricDouble('power_output') ?? 0.0;
        final int gear = model?.vehicle.getMetric('gear') ?? 0;

        // Vehicle must be in drive or reverse to show power.
        final bool visible = (gear == 4 || gear == 2);
        if (!visible) power = 0;

        return Row(
          children: [
            Expanded(
              child: FractionallySizedBox(
                alignment: Alignment.topRight,
                widthFactor: ((-power / inMaxPower)).clamp(0, 1),
                child: Container(
                  color: inColor,
                  height: 5
                ),
              ),
            ),
            Expanded(
              child: FractionallySizedBox(
                alignment: Alignment.topLeft,
                widthFactor: ((power / outMaxPower)).clamp(0, 1),
                child: Container(
                  color: outColor,
                  height: 5
                ),
              ),
            )
          ],
        );
      }
    );
  }
}
