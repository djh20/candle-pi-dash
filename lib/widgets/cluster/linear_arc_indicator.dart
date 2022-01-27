import 'dart:math';
import 'package:flutter/material.dart';

const double arcRadius = 32;

const double startAngle = (-75 / 360) * pi;
const double sweepAngle = (135 / 360) * pi;

final arcPaint = Paint()
  ..style = PaintingStyle.stroke
  ..strokeWidth = 5
  ..strokeCap = StrokeCap.round;

class LinearArcIndicator extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final IconData icon;

  const LinearArcIndicator({ 
    Key? key,
    required this.value,
    required this.min,
    required this.max,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color hintColor = theme.hintColor;

    // Convert range so min can be zero.
    final double reducedValue = value - min;
    final double reducedMax = max - min;

    final double scale = (reducedValue / reducedMax).clamp(0, 1);

    final HSVColor hsvColor = HSVColor.lerp(
      HSVColor.fromColor(Colors.red), 
      HSVColor.fromColor(Colors.green), 
      scale
    ) ?? HSVColor.fromColor(hintColor);

    final Color color = hsvColor.toColor();
    
    return Row(
      children: [
        Icon(
          icon,
          color: color,
          size: 32
        ),
        
        CustomPaint(
          painter: ArcPainter(
            emptyColor: hintColor,
            fullColor: color,
            scale: scale
          )
        ),
        
      ],
    );
  }
}

class ArcPainter extends CustomPainter {
  final Color emptyColor;
  final Color fullColor;
  final double scale;

  ArcPainter({
    required this.emptyColor,
    required this.fullColor,
    required this.scale
  });

  @override
  void paint(Canvas canvas, Size size) {
    const Offset center = Offset((-arcRadius)+3, 0);
    final Rect rect = Rect.fromCircle(center: center, radius: arcRadius);

    arcPaint.color = emptyColor;
    
    canvas.drawArc(
      rect,
      startAngle,
      sweepAngle,
      false, 
      arcPaint
    );

    if (scale > 0) {
      arcPaint.color = fullColor;

      canvas.drawArc(
        rect,
        startAngle + (sweepAngle * (1-scale)),
        sweepAngle * scale,
        false, 
        arcPaint
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
  @override
  bool shouldRebuildSemantics(covariant CustomPainter oldDelegate) => false;
}