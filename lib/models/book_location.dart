class BookLocation {
  String level;
  String room;
  String imgUrl;

  BookLocation({
    required this.level,
    required this.room,
    this.imgUrl = '',
  });

  factory BookLocation.fromJson(Map<String, dynamic> json) {
    return BookLocation(
      level: json['nivel'] as String? ?? '',
      room: json['sala'] as String? ?? '',
      imgUrl: json['imagen'] as String? ?? '',
    );
  }
}
