class AppConstants {
  static const String appName = 'BlockMate';
  static const String blogDataKey = 'blogData';

  // Override at build/run time with:
  // flutter run --dart-define=API_BASE_URL=http://localhost:8000/api/v1
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://blockmate.onrender.com/api/v1',
  );

  static const List<Map<String, String>> semesters = [
    {'id': '1', 'title': 'Physics and Chemistry Cycle'},
    {'id': '2', 'title': 'Third Semester'},
    {'id': '3', 'title': 'Fourth Semester'},
    {'id': '4', 'title': 'Fifth Semester'},
    {'id': '5', 'title': 'Sixth Semester'},
    {'id': '6', 'title': 'Seventh Semester'},
    {'id': '7', 'title': 'Eighth Semester'},
  ];
}
