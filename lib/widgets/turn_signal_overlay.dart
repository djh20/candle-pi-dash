import 'package:candle_dash/model.dart';
import 'package:flutter/material.dart';
import 'package:property_change_notifier/property_change_notifier.dart';

class TurnSignalOverlay extends StatefulWidget {
  const TurnSignalOverlay({Key? key}) : super(key: key);

  @override
  State<TurnSignalOverlay> createState() => _TurnSignalOverlayState();
}

class _TurnSignalOverlayState extends State<TurnSignalOverlay> 
with TickerProviderStateMixin {
  
  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 500),
    upperBound: 0.7,
    lowerBound: 0.2,
    vsync: this,
  )..repeat(reverse: true);

  @override
  Widget build(BuildContext context) {
    return PropertyChangeConsumer<AppModel, String>(
      properties: const ['left_turn_signal', 'right_turn_signal'],
      builder: (context, model, properties) {
        final bool leftTurnSignal = model?.vehicle.metrics['left_turn_signal']?.value ?? false;
        final bool rightTurnSignal = model?.vehicle.metrics['right_turn_signal']?.value ?? false;

        return IgnorePointer(
          child: Stack(
            children: [
              TurnSignalEffect(
                controller: _controller, 
                visible: leftTurnSignal,
                colors: [
                  Colors.green,
                  Colors.green.withOpacity(0)
                ],
                stops: const [0, 0.5]
              ),
              TurnSignalEffect(
                controller: _controller, 
                visible: rightTurnSignal,
                colors: [
                  Colors.green.withOpacity(0),
                  Colors.green
                ],
                stops: const [0.5, 1],
              )
            ],
          ),
        );
      }
    );
  }
}

class TurnSignalEffect extends StatelessWidget {
  final AnimationController controller;
  final List<Color> colors;
  final List<double> stops;
  final bool visible;

  const TurnSignalEffect({
    Key? key,
    required this.controller,
    required this.colors,
    required this.stops,
    this.visible = true
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: const Duration(milliseconds: 200),
      child: FadeTransition(
        opacity: controller,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              stops: stops,
              colors: colors
            )
          )
        ),
      ),
    );
  }
}
