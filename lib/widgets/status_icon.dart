import 'package:flutter/material.dart';

class StatusIcon extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final bool active;
  final double size;

  const StatusIcon({ 
    Key? key,
    required this.icon,
    this.color,
    this.active = true,
    this.size = 22
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: active ? 1 : 0.1,
      duration: const Duration(milliseconds: 500),
      child: Icon(
        icon,
        size: size,
        color: color,
      ),
    );
  }
}