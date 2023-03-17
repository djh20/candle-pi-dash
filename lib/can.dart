import 'dart:async';

import 'package:candle_dash/utils.dart';

class TopicGroup {
  final String name;
  //final int mask;
  //final int filter;
  final Duration timeout;
  final List<Topic> topics;

  //late final String maskHex;
  //late final String filterHex;

  TopicGroup({
    required this.name,
    //required this.mask,
    //required this.filter,
    required this.timeout,
    this.topics = const []
  }) {
    //maskHex = intToHex(mask, 3);
    //filterHex = intToHex(filter, 3);
  }
}

class Topic {
  final int id;
  final String name;
  final int bytes;
  //final bool Function() shouldWait;
  //final bool important;
  final bool Function() isEnabled;

  late final String idHex;

  Topic({
    required this.id,
    required this.name,
    required this.bytes,
    required this.isEnabled,
    //this.important = true
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

class Command {
  late final String text;
  final Duration timeout;
  late final List<String> validResponses;
  final completer = Completer<String?>();

  Command(String text, {
    this.timeout = const Duration(milliseconds: 200),
    List<String>? validResponses
  }) {
    this.text = text.replaceAll(' ', '').toUpperCase();
    this.validResponses = validResponses ?? [this.text];
  }
}
