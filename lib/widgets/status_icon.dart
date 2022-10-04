import 'package:flutter/material.dart';

class StatusIcon extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final bool active;
  final String? activeText;
  final bool compact;

  const StatusIcon({ 
    Key? key,
    required this.icon,
    this.color,
    this.active = true,
    this.activeText,
    this.compact = false
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: active ? 1 : 0.05,
      duration: const Duration(milliseconds: 500),
      child: Row(
        children: [
          Icon(
            icon,
            size: 22,
            color: color
          ),
          const SizedBox(width: 3),
          if (activeText != null)
            AnimatedOpacity(
              opacity: (active && !compact) ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: Text(
                activeText ?? "",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: color
                )
              )
            )
        ],
      ),
    );
  }
}