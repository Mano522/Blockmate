import 'study_file.dart';

class Subject {
  const Subject({
    required this.id,
    required this.title,
    required this.semester,
    required this.order,
    required this.files,
  });

  final String id;
  final String title;
  final String semester;
  final int order;
  final List<StudyFile> files;

  factory Subject.fromJson(Map<String, dynamic> json) {
    final rawFiles = (json['files'] as List?) ?? const [];
    return Subject(
      id: (json['_id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      semester: (json['semester'] ?? '').toString(),
      order: (json['order'] ?? 0) is int
          ? (json['order'] ?? 0) as int
          : int.tryParse((json['order'] ?? '0').toString()) ?? 0,
      files: rawFiles
          .whereType<Map>()
          .map((e) => StudyFile.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}
