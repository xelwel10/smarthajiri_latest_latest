class Notimessage {
  final String title;
  final String message;
  final String date;
  final String read;

  const Notimessage({
    required this.title,
    required this.message,
    required this.date,
    required this.read,
  });
  toJson() {
    return {
      "title": title,
      "message": message,
      "date": date,
      "read": read,
    };
  }

  Map<String, dynamic> fromJson(Notimessage info) => <String, dynamic>{
        'title': info.title,
        'message': info.message,
        'date': info.date,
        'read': info.read,
      };
}
