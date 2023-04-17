

import 'dart:async';
import 'package:candle_dash/can.dart';
import 'package:candle_dash/utils.dart';
import 'package:candle_dash/vehicle.dart';

enum ElmTaskStatus {
  running,
  completing,
  completed
}

abstract class ElmTask {
  final String name;
  final Vehicle vehicle;
  final Duration timeout;
  final bool Function() isEnabled;
  final Duration? cooldown;
  
  var status = ElmTaskStatus.completed;

  Timer? _timeoutTimer;
  Completer<void>? _completer;

  ElmTask({
    required this.name,
    required this.vehicle,
    required this.timeout,
    required this.isEnabled,
    this.cooldown,
  });

  Future<void> run() async {
    _completer = Completer<void>();
    _timeoutTimer = Timer(timeout, complete);
    return _completer!.future;
  }

  void processTopicData(CanTopic topic, List<int> data);
  
  Future<void> complete() async {
    _timeoutTimer?.cancel();
    _completer?.complete();
    status = ElmTaskStatus.completed;
  }
}

class ElmMonitorTask extends ElmTask {
  List<CanTopic> topics;

  final List<CanTopic> _pendingTopics = [];

  ElmMonitorTask({
    required super.name,
    required super.vehicle,
    required super.timeout,
    required super.isEnabled,
    super.cooldown,
    required this.topics
  });

  @override
  Future<void> run() async {
    status = ElmTaskStatus.running;
    //List<CanTopic> enabledTopics = topics.where((topic) => topic.isEnabled()).toList();
    List<int> ids = topics.map((topic) => topic.id).toList();

    int filter = ids[0];
    for (int i = 1; i < ids.length; i++) {
      filter = filter & ids[i];
    }
    
    int mask = ~ids[0];
    for (int i = 1; i < ids.length; i++) {
      mask = mask & ~ids[i];
    }
    mask = (mask | filter) & 0x7FF;

    String filterHex = intToHex(filter, 3);
    String maskHex = intToHex(mask, 3);

    await vehicle.sendCommand(ElmCommand('AT CM $maskHex'));
    await vehicle.sendCommand(ElmCommand('AT CF $filterHex'));

    _pendingTopics.addAll(topics);
    
    await vehicle.sendCommand(ElmCommand("AT MA"));
    return super.run();
  }

  @override
  Future<void> complete() async {
    if (status != ElmTaskStatus.running) return;
    status = ElmTaskStatus.completing;

    _pendingTopics.clear();
    await vehicle.sendCommand(ElmCommand('STOP', validResponses: ['STOPPED', '?']));
    await super.complete();
  }
  
  @override
  void processTopicData(CanTopic topic, List<int> data) {
    if (_pendingTopics.remove(topic) && _pendingTopics.isEmpty) {
      complete();
    }
  }
}

class ElmPollTask extends ElmTask {
  final CanTopic topic;
  final int header;
  final int flowDelay;
  final List<String> requests;

  ElmPollTask({
    required super.name,
    required super.vehicle,
    required super.timeout,
    required super.isEnabled,
    super.cooldown,
    required this.topic,
    required this.header,
    this.flowDelay = 0,
    required this.requests
  });
  
  @override
  Future<void> run() async {
    status = ElmTaskStatus.running;
    
    await vehicle.sendCommand(ElmCommand('AT AR'));
    await vehicle.sendCommand(ElmCommand('AT FC SD 3000' + intToHex(flowDelay, 2)));
    await vehicle.sendCommand(ElmCommand('AT SH ' + intToHex(header, 3)));
    await vehicle.sendCommand(ElmCommand('AT FC SH ' + intToHex(header, 3)));
    
    for (var request in requests) {
      await vehicle.sendCommand(
        ElmCommand(
          request,
          validResponses: [],
          timeout: const Duration(seconds: 2)
        )
      );
    }

    return super.run();
  }

  @override
  Future<void> complete() async {
    if (status != ElmTaskStatus.running) return;
    await super.complete();
  }
  
  @override
  void processTopicData(CanTopic topic, List<int> data) {
    // TODO: implement processTopicData
  }
}

class ElmCommand {
  late final String text;
  final Duration timeout;
  late final List<String> validResponses;
  final completer = Completer<String?>();

  ElmCommand(String text, {
    this.timeout = const Duration(milliseconds: 200),
    List<String>? validResponses
  }) {
    this.text = text.replaceAll(' ', '').toUpperCase();
    this.validResponses = validResponses ?? [this.text];
  }
}
