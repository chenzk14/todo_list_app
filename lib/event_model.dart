class Event {
  String name;
  DateTime date;

  Event({required this.name, required this.date});

  // 将事件对象转换为 JSON 格式
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'date': date.toIso8601String(),
    };
  }

  // 从 JSON 格式创建事件对象
  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      name: json['name'],
      date: DateTime.parse(json['date']),
    );
  }
}