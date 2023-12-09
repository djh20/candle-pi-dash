import 'package:flutter/material.dart';

class UnitText extends StatelessWidget {
  final String text;
  final String? unit;
  final double scale;

  const UnitText(this.text, { 
    Key? key,
    this.unit,
    this.scale = 1
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: 42 * scale,
            fontWeight: FontWeight.bold
          )
        ),

        if (unit != null) ...[
          // Add spacing between value and unit.
          const SizedBox(width: 2),

          Text(
            (unit ?? ''),
            style: TextStyle(
              fontSize: 20 * scale,
              height: 2.2
            )
          )
        ]
      ]
    );
  }
}