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
    upperBound: 0.8,
    lowerBound: 0.3,
    vsync: this,
  )..repeat(reverse: true);

  @override
  Widget build(BuildContext context) {
    return PropertyChangeConsumer<AppModel, String>(
      properties: const ['turn_signal'],
      builder: (context, model, properties) {
        final int turnSignal = model?.vehicle.getMetric('turn_signal');

        final bool leftTurnSignal = (turnSignal == 1 || turnSignal == 3);
        final bool rightTurnSignal = (turnSignal == 2 || turnSignal == 3);

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
