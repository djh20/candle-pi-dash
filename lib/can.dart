class Topic {
  final String id;
  final String? name;
  final int bytes;
  final Duration interval;
  final bool highPriority;

  Topic({
    required this.id,
    this.name,
    required this.bytes,
    required this.interval,
    this.highPriority = false
  });
}

class Metric {
  final String id;
  Function(Metric)? onUpdate;

  dynamic defaultValue;
  
  dynamic _value = 0;
  get value => _value;

  Metric({
    required this.id,
    this.defaultValue = 0
  }) {
    _value = defaultValue;
  }

  void setValue(dynamic newValue) {
    if (newValue == _value) return;

    _value = newValue;
    if (onUpdate != null) onUpdate!(this); 
  }
}
