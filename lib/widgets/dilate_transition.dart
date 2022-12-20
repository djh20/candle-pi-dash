import 'package:flutter/material.dart';

class DilateTransition extends StatelessWidget {
  final Widget? child;
  final Animation<double> animation;

  const DilateTransition({
    Key? key,
    this.child,
    required this.animation
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: Tween(begin: 0.95, end: 1.0).animate(animation),
        child: child
      ),
    );
  }
}