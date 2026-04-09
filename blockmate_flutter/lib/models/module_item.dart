import 'study_file.dart';

class ModuleItem {
  const ModuleItem({
    required this.id,
    required this.title,
    required this.subject,
    required this.order,
    required this.files,
  });

  final String id;
  final String title;
  final String subject;
  final int order;
  final List<StudyFile> files;

  factory ModuleItem.fromJson(Map<String, dynamic> json) {
    final rawFiles = (json['files'] as List?) ?? const [];
    return ModuleItem(
      id: (json['_id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      subject: (json['subject'] ?? '').toString(),
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
