import 'dart:async';

class Topic {
  final String id;
  final String? name;
  final int bytes;

  Topic({
    required this.id,
    this.name,
    required this.bytes
  });
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
