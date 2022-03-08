import 'package:flutter/material.dart';

class MetricDisplay extends StatelessWidget {
  final String name;
  final String value;

  const MetricDisplay({ 
    Key? key,
    required this.name,
    required this.value
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
              fontSize: 24
            )
          ),
        ),
        const SizedBox(width: 10),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold
          )
        ),
      ],
    );
  }
}