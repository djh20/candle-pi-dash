import 'dart:async';

import 'package:candle_dash/utils.dart';

class TopicGroup {
  final String? name;
  final int mask;
  final int filter;
  final Duration duration;
  final List<Topic> topics;

  late final String maskHex;
  late final String filterHex;

  TopicGroup({
    this.name,
    required this.mask,
    required this.filter,
    required this.duration,
    this.topics = const []
  }) {
    maskHex = intToHex(mask, 3);
    filterHex = intToHex(filter, 3);
  }
}

class Topic {
  final int id;
  final String name;
  final int bytes;

  late final String idHex;

  Topic({
    required this.id,
    required this.name,
    required this.bytes
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
