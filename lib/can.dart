import 'dart:async';
import 'package:candle_dash/utils.dart';

class CanTopic {
  final int id;
  final String name;
  final int bytes;
  final Duration interval;
  //final bool Function() isEnabled;
  final void Function(List<int> data, int frameIndex)? processFrame;

  late final String idHex;

  CanTopic({
    required this.id,
    required this.name,
    required this.bytes,
    required this.interval,
    //required this.isEnabled,
    this.processFrame
  }) {
    idHex = intToHex(id, 3);
  }
}

class Metric {
  final String id;
  Function(Metric)? onUpdate;
  final Duration? timeout;
  Timer? timeoutTimer;

  dynamic defaultValue;
  
  dynamic _value = 0;
  get value => _value;

  Metric({
    required this.id,
    this.defaultValue = 0,
    this.timeout
  }) {
    _value = defaultValue;
  }

  void setValue(dynamic newValue) {
    if (timeout != null) {
      timeoutTimer?.cancel();
      timeoutTimer = Timer(timeout!, reset);
    }

    if (newValue == _value) return;

    _value = newValue;
    if (onUpdate != null) onUpdate!(this); 
  }

  void reset() => setValue(defaultValue);
}
