

import 'dart:async';
import 'package:candle_dash/can.dart';
import 'package:candle_dash/utils.dart';
import 'package:candle_dash/vehicle.dart';

enum ElmConnectionType {
  bluetooth,
  wifi
}

abstract class ElmTask {
  final String name;
  final Vehicle vehicle;
  final int? priority;
  final Duration maxDuration;
  final Duration? interval;
  final bool Function() isEnabled;

  ElmTask({
    required this.name,
    required this.vehicle,
    this.priority,
    required this.maxDuration,
    this.interval,
    required this.isEnabled,
  });

  Future<void> run();
  //void processTopicData(CanTopic topic, List<int> data);
}

class ElmMonitorTask extends ElmTask {
  final List<CanTopic> topics;

  ElmMonitorTask({
    required super.name,
    required super.vehicle,
    super.priority,
    required super.maxDuration,
    super.interval,
    required super.isEnabled,
    required this.topics
  });

  @override
  Future<void> run() async {
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

    final gotPrompt = await vehicle.sendCommand(
      ElmCommand("AT MA", timeout: maxDuration)
    );

    if (!gotPrompt) {
      await vehicle.sendCommand(ElmCommand('STOP'));
    }
  }
  
  /*
  @override
  void processTopicData(CanTopic topic, List<int> data) {
    //_remainingTopics.remove(topic);
  }
  */
}

/*
class ElmPollTask extends ElmTask {
  final CanTopic responseTopic;
  final int header;
  final int flowDelay;
  final List<String> requests;

  ElmPollTask({
    required super.name,
    required super.vehicle,
    //required super.timeout,
    required super.isEnabled,
    super.cooldown,
    required this.responseTopic,
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
          timeout: const Duration(milliseconds: 200)
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
*/

class ElmCommand {
  late final String text;
  final Duration timeout;
  final completer = Completer<bool>();
  Timer? timer;

  ElmCommand(String text, {
    this.timeout = const Duration(milliseconds: 200)
  }) {
    this.text = text.replaceAll(' ', '').toUpperCase();
  }
}
