import 'package:flutter/material.dart';

class StatusIcon extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final bool active;
  final String? text;
  final double size;
  final bool compact;

  const StatusIcon({ 
    Key? key,
    required this.icon,
    this.color,
    this.active = true,
    this.text,
    this.size = 34,
    this.compact = false
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      curve: Curves.fastOutSlowIn,
      opacity: active ? 1 : 0,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: size),
        child: AnimatedFractionallySizedBox(
          duration: const Duration(milliseconds: 250),
          curve: Curves.fastOutSlowIn,
          heightFactor: active ? 1 : 0,
          child: Row(
            children: [
              Icon(
                icon,
                size: size,
                color: color
              ),
              const SizedBox(width: 3),
              if (text != null)
                AnimatedOpacity(
                  opacity: (active && !compact) ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    text ?? "",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: color
                    )
                  )
                )
            ]
            ),
          ),
      ),
    );
  }
}