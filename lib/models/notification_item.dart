class NotificationItem {
  final String title;
  final String message;
  final String type;
  final DateTime createdAt;

  NotificationItem({
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
