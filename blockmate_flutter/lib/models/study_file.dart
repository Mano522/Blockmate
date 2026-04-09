class StudyFile {
  const StudyFile({
    required this.id,
    required this.name,
    required this.url,
    this.createdAt,
  });

  final String id;
  final String name;
  final String url;
  final DateTime? createdAt;

  bool get isExternal => url.startsWith('http://') || url.startsWith('https://');

  factory StudyFile.fromJson(Map<String, dynamic> json) {
    return StudyFile(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      url: (json['url'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
    );
  }
}
