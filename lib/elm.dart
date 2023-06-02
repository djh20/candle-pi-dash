

import 'dart:async';
import 'package:candle_dash/can.dart';
import 'package:candle_dash/utils.dart';
import 'package:candle_dash/vehicle.dart';

abstract class ElmTask {
  final String name;
  final Vehicle vehicle;
  final bool Function() isEnabled;

  ElmTask({
    required this.name,
    required this.vehicle,
    required this.isEnabled
  });

  Future<void> run();
  void processTopicData(CanTopic topic, List<int> data);
}

class ElmMonitorTask extends ElmTask {
  final List<CanTopic> topics;
  final List<CanTopic> desiredTopics;

  final List<CanTopic> _remainingTopics = [];

  ElmMonitorTask({
    required super.name,
    required super.vehicle,
    required super.isEnabled,
    required this.topics,
    required this.desiredTopics
  });

  @override
  Future<void> run() async {
    _remainingTopics.addAll(desiredTopics);

    // Sort from lowest id to highest id.
    _remainingTopics.sort((a, b) => a.id - b.id);
    
    while (_remainingTopics.isNotEmpty) {
      final List<CanTopic> selectedTopics = []; 
      int filter = _remainingTopics[0].id;
      int inverseFilter = ~filter;

      for (int i = 1; i < _remainingTopics.length; i++) {
        final topic = _remainingTopics[i];

        final int newFilter = filter & topic.id;
        final int newInverseFilter = inverseFilter & ~topic.id;
        final int mask = (newFilter | newInverseFilter) & 0x7FF;

        final matchingTopics = topics.where((topic) => (topic.id & mask) == newFilter);
        final bytesPerSec = matchingTopics.fold<double>(
          0, 
          (val, topic) => (val + (1/topic.interval.inSeconds) * topic.bytes)
        );

        if (bytesPerSec <= 1600) {
          filter = newFilter;
          inverseFilter = newInverseFilter;
          selectedTopics.add(topic);
        }
      }
      
      for (var topic in selectedTopics) {
        _remainingTopics.remove(topic);
      }

      final int mask = (filter | inverseFilter) & 0x7FF;
      final String filterHex = intToHex(filter, 3);
      final String maskHex = intToHex(mask, 3);

      vehicle.model.log(selectedTopics.toString(), category: 3);
      await vehicle.sendCommand(ElmCommand('AT CM $maskHex'));
      await vehicle.sendCommand(ElmCommand('AT CF $filterHex'));

      final gotPrompt = await vehicle.sendCommand(
        ElmCommand("AT MA", timeout: const Duration(milliseconds: 200))
      );

      if (!gotPrompt) {
        await vehicle.sendCommand(ElmCommand('STOP'));
      }
    }
  }
  
  @override
  void processTopicData(CanTopic topic, List<int> data) {
    _remainingTopics.remove(topic);
  }
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
