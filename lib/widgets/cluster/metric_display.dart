import 'package:flutter/material.dart';

class MetricDisplay extends StatelessWidget {
  final String name;
  final String value;
  final Color? valueColor;

  const MetricDisplay({ 
    Key? key,
    required this.name,
    required this.value,
    this.valueColor
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Opacity(
          opacity: 0.8,
          child: Text(
            name,
            style: const TextStyle(
              fontSize: 26
            )
          ),
        ),
        const SizedBox(width: 10),
        Text(
          value,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: valueColor
          )
        ),
      ],
    );
  }
}