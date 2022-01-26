import 'dart:math';

import 'package:flutter/material.dart';
import 'package:property_change_notifier/property_change_notifier.dart';
import 'package:dash_delta/model.dart';

const double arcRadius = 300;

const double outArcStart = (122 / 360) * pi;
const double outArcSweep = (70 / 360) * pi;

const double inArcStart = (198 / 360) * pi;
const double inArcSweep = (40 / 360) * pi;

const Offset center = Offset(0, -arcRadius);
final Rect rect = Rect.fromCircle(center: center, radius: arcRadius);

const double inMaxPower = 30;
const double outMaxPower = 90;

final arcPaint = Paint()
  ..style = PaintingStyle.stroke
  ..strokeWidth = 10
  ..strokeCap = StrokeCap.round;

class PowerBar extends StatelessWidget {
  const PowerBar({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    Color contrasting = theme.textTheme.bodyText1?.color ?? Colors.black;

    return SizedBox(
      width: 300,
      height: 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            painter: BackgroundPainter(
              contrasting: contrasting 
            )
          ),
          PowerBarOverlay(
            contrasting: contrasting,
          )
        ],
      )
    );
  }
}

class BackgroundPainter extends CustomPainter {
  final Color contrasting;

  BackgroundPainter({
    required this.contrasting
  });

  @override
  void paint(Canvas canvas, Size size) {
    //print('background paint');

    arcPaint.color = contrasting.withOpacity(0.085);
    
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
      properties: const ['power', 'powered'],
      builder: (context, model, properties) {
        final double power = model?.vehicle.getMetricDouble('power') ?? 0.0;
        final bool powered = model?.vehicle.getMetricBool('powered') ?? false;
        
        return CustomPaint(
          // Only show overlay if vehicle is powered.
          painter: powered ? OverlayPainter(
            contrasting: contrasting,
            outFactor: (-power / outMaxPower).clamp(0, 1),
            inFactor: (power / inMaxPower).clamp(0, 1)
          ) : null
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
      arcPaint.color = contrasting.withOpacity(0.4);

      canvas.drawArc(
        rect,
        outArcStart + (outArcSweep * (1-outFactor)),
        outArcSweep * outFactor,
        false, 
        arcPaint
      );
    }

    if (inFactor > 0) {
      arcPaint.color = const Color.fromRGBO(31, 240, 87, 1);

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
