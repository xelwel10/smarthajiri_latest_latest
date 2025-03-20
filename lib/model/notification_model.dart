class NotificationItem {
  final String title;
  final String message;
  final DateTime date;
  bool read;
  final int id;
  final int empid;

  NotificationItem({
    required this.title,
    required this.message,
    required this.date,
    required this.id,
    required this.empid,
    this.read = false,
  });

  NotificationItem copyWith({
    int? id,
    int? empid,
    String? title,
    String? message,
    DateTime? date,
    bool? read,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      empid: empid ?? this.empid,
      title: title ?? this.title,
      message: message ?? this.message,
      date: date ?? this.date,
      read: read ?? this.read,
    );
  }
}
