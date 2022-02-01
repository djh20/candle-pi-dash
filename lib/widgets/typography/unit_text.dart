import 'package:flutter/material.dart';

class UnitText extends StatelessWidget {
  final String text;
  final String unit;

  const UnitText(this.text, this.unit, { 
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.65,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            text,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold
            )
          ),
    
          // Add spacing between value and unit.
          const SizedBox(width: 2),
    
          Text(
            unit,
            style: const TextStyle(
              fontSize: 14,
              height: 2.2,
            )
          ),
        ]
      ),
    );
  }
}