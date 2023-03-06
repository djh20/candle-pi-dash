class Topic {
  final int id;
  final String? name;
  final int intervalMs;
  final bool highPriority;
  //final List<Metric> metrics;

  Topic({
    required this.id,
    this.name,
    required this.intervalMs,
    this.highPriority = false
    //this.metrics = const []
  });
}

class Metric {
  final String id;
  //final Function(Uint8List)? processFrame;
  Function(Metric)? onUpdate;

  dynamic _value = 0;
  get value => _value;

  Metric({
    required this.id,
    //this.processFrame
  });

  void setValue(dynamic newValue) {
    if (newValue == _value) return;

    _value = newValue;
    if (onUpdate != null) onUpdate!(this); 
  }
}
