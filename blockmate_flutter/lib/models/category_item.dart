class CategoryItem {
  const CategoryItem({
    required this.id,
    required this.title,
    required this.desc,
    required this.subjectId,
    required this.moduleId,
    this.subjectTitle,
    this.moduleTitle,
  });

  final String id;
  final String title;
  final String desc;
  final String subjectId;
  final String moduleId;
  final String? subjectTitle;
  final String? moduleTitle;

  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    final subject = json['subject'];
    final module = json['module'];

    String subjectId = '';
    String moduleId = '';
    String? subjectTitle;
    String? moduleTitle;

    if (subject is Map) {
      subjectId = (subject['_id'] ?? '').toString();
      subjectTitle = subject['title']?.toString();
    } else {
      subjectId = (subject ?? json['subjectId'] ?? '').toString();
    }

    if (module is Map) {
      moduleId = (module['_id'] ?? '').toString();
      moduleTitle = module['title']?.toString();
    } else {
      moduleId = (module ?? json['moduleId'] ?? '').toString();
    }

    return CategoryItem(
      id: (json['_id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      desc: (json['desc'] ?? '').toString(),
      subjectId: subjectId,
      moduleId: moduleId,
      subjectTitle: subjectTitle,
      moduleTitle: moduleTitle,
    );
  }
}
