import 'package:flutter/material.dart';

class LargeUnitText extends StatelessWidget {
  final String text;
  final String? unit;

  const LargeUnitText(this.text, { 
    Key? key,
    this.unit
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold
          )
        ),

        if (unit != null) 
          // Add spacing between value and unit.
          const SizedBox(width: 2),

        if (unit != null) 
          Text(
            (unit ?? '').toLowerCase(),
            style: const TextStyle(
              fontSize: 20,
              height: 2.1
            )
          ),
      ]
    );
  }
}