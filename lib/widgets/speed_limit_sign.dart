import 'package:flutter/material.dart';

class SpeedLimitSign extends StatelessWidget {
  final bool visible;
  final int speedLimit;

  const SpeedLimitSign({ 
    Key? key,
    required this.speedLimit,
    this.visible = true
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: visible ? 1.0 : 0.0,
      duration: const Duration(seconds: 1),
      child: Row(
        children: [
          /*
          Text(
            streetName ?? '',
            style: const TextStyle(
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 7),
          */
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 56,
                width: 56,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red
                ),
              ),
              Container(
                height: 42,
                width: 42,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white
                ),
              ),
              Text(
                speedLimit.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 21,
                  fontWeight: FontWeight.bold
                ),
              )
            ],
          ),
        ]
      )
    );
  }
}