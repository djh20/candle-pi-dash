import 'dart:math';

import 'package:flutter/material.dart';
import 'package:property_change_notifier/property_change_notifier.dart';
import 'package:dash_delta/model.dart';

const double arcRadius = 300;

const double outArcStart = (124 / 360) * pi;
const double outArcSweep = (70 / 360) * pi;

const double inArcStart = (196 / 360) * pi;
const double inArcSweep = (40 / 360) * pi;

const Offset center = Offset(0, (-arcRadius)+3);
final Rect rect = Rect.fromCircle(center: center, radius: arcRadius);

const double inMaxPower = 30;
const double outMaxPower = 85;
const double arcDeadZone = 0.015;

final arcPaint = Paint()
  ..style = PaintingStyle.stroke
  ..strokeWidth = 5;
  //..strokeCap = StrokeCap.butt;

class PowerBar extends StatelessWidget {
  const PowerBar({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    Color contrastingColor = theme.textTheme.bodyText1?.color ?? Colors.black;
    Color hintColor = theme.hintColor;

    return SizedBox(
      width: 300,
      height: 25,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            painter: BackgroundPainter(
              color: hintColor 
            )
          ),
          PowerBarOverlay(
            contrasting: contrastingColor,
          )
        ],
      )
    );
  }
}

class BackgroundPainter extends CustomPainter {
  final Color color;

  BackgroundPainter({
    required this.color
  });

  @override
  void paint(Canvas canvas, Size size) {
    arcPaint.color = color;
    
    canvas.drawArc(
      rect,
      outArcStart,
      outArcSweep,
      false, 
      arcPaint
    );

    canvas.drawArc(
      rect,
      inArcStart,
      inArcSweep,
      false, 
      arcPaint
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
  @override
  bool shouldRebuildSemantics(covariant CustomPainter oldDelegate) => false;
}

class PowerBarOverlay extends StatelessWidget {
  final Color contrasting;

  const PowerBarOverlay({
     Key? key,
     required this.contrasting
   }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PropertyChangeConsumer<AppModel, String>(
      properties: const ['power', 'powered', 'gear'],
      builder: (context, model, properties) {
        final double power = model?.vehicle.getMetricDouble('power') ?? 0.0;
        //final bool powered = model?.vehicle.getMetricBool('powered') ?? false;
        final int gear = model?.vehicle.getMetric('gear') ?? 0;

        // Vehicle must be in drive or reverse to show power.
        final bool visible = (gear == 4 || gear == 2);

        return Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              // Only show overlay if vehicle is powered.
              painter: visible ? OverlayPainter(
                contrasting: contrasting,
                outFactor: ((-power / outMaxPower) - arcDeadZone).clamp(0, 1),
                inFactor: ((power / inMaxPower) - arcDeadZone).clamp(0, 1)
              ) : null
            ),
          ]
        );
      }
    );
  }
}

class OverlayPainter extends CustomPainter {
  final Color contrasting;
  final double inFactor;
  final double outFactor;

  OverlayPainter({
    required this.contrasting,
    this.inFactor = 0,
    this.outFactor = 0
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (outFactor > 0) {
      arcPaint.color = contrasting;

      canvas.drawArc(
        rect,
        outArcStart + (outArcSweep * (1-outFactor)),
        outArcSweep * outFactor,
        false, 
        arcPaint
      );
    }

    if (inFactor > 0) {
      arcPaint.color = const Color.fromRGBO(30, 212, 51, 1);

      canvas.drawArc(
        rect,
        inArcStart,
        inArcSweep * inFactor,
        false, 
        arcPaint
      );
    }
  }

  @override
  bool shouldRepaint(covariant OverlayPainter oldDelegate) {
    // Arcs should be repainted if values have changed.
    return (
      oldDelegate.inFactor != inFactor || 
      oldDelegate.outFactor != outFactor
    );
  }
}
