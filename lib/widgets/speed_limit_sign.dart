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
      duration: const Duration(milliseconds: 500),
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
                height: 68,
                width: 68,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red
                ),
              ),
              Container(
                height: 52,
                width: 52,
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
                  fontSize: 27,
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