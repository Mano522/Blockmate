import 'package:dio/dio.dart';

import '../models/category_item.dart';
import '../models/module_item.dart';
import '../models/subject.dart';
import 'api_client.dart';

class ContentService {
  ContentService(this._api);

  final ApiClient _api;

  Future<List<CategoryItem>> searchCategories(String search) async {
    final data = await _api.get('/categories', query: {'search': search});
    final list = (data as List).whereType<Map>();
    return list
        .map((e) => CategoryItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<Subject>> fetchSubjects({String? semester, String? title}) async {
    final query = <String, dynamic>{};
    if (semester != null && semester.isNotEmpty) query['semester'] = semester;
    if (title != null && title.isNotEmpty) query['title'] = title;

    final data = await _api.get('/subjects', query: query);
    final list = (data as List).whereType<Map>();
    return list.map((e) => Subject.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<void> addSubject({
    required String title,
    required String semester,
    required int order,
  }) async {
    await _api.post('/subjects', {
      'title': title,
      'semester': semester,
      'order': order,
    });
  }

  Future<void> deleteSubject(String id) async {
    await _api.delete('/subjects/$id');
  }

  Future<List<ModuleItem>> fetchModules({required String subjectId}) async {
    final data = await _api.get('/modules', query: {'subjectId': subjectId});
    final list = (data as List).whereType<Map>();
    return list.map((e) => ModuleItem.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<ModuleItem> fetchModule(String moduleId) async {
    final data = await _api.get('/modules/$moduleId');
    return ModuleItem.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<void> addModule({
    required String title,
    required String subjectId,
    required int order,
  }) async {
    await _api.post('/modules', {
      'title': title,
      'subject': subjectId,
      'order': order,
    });
  }

  Future<void> deleteModule(String id) async {
    await _api.delete('/modules/$id');
  }

  Future<List<CategoryItem>> fetchCategories({
    String? search,
    String? subjectId,
    String? moduleId,
  }) async {
    final query = <String, dynamic>{};
    if (search != null && search.isNotEmpty) query['search'] = search;
    if (subjectId != null && subjectId.isNotEmpty) query['subjectId'] = subjectId;
    if (moduleId != null && moduleId.isNotEmpty) query['moduleId'] = moduleId;

    final data = await _api.get('/categories', query: query);
    final list = (data as List).whereType<Map>();
    return list
        .map((e) => CategoryItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<CategoryItem> fetchCategory(String id) async {
    final data = await _api.get('/categories/$id');
    return CategoryItem.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<void> addCategory({
    required String title,
    required String desc,
    required String subjectId,
    required String moduleId,
  }) async {
    await _api.post('/categories', {
      'title': title,
      'desc': desc,
      'subjectId': subjectId,
      'moduleId': moduleId,
    });
  }

  Future<void> updateCategory({
    required String id,
    required String title,
    required String desc,
  }) async {
    await _api.put('/categories/$id', {
      'title': title,
      'desc': desc,
    });
  }

  Future<void> deleteCategory(String id) async {
    await _api.delete('/categories/$id');
  }

  Future<void> uploadFile({
    required String type,
    required String id,
    required String filePath,
    required String displayName,
  }) async {
    final formData = FormData.fromMap({
      'name': displayName,
      'file': await MultipartFile.fromFile(filePath),
    });
    await _api.raw.post('/upload/$type/$id', data: formData);
  }

  Future<void> addLink({
    required String type,
    required String id,
    required String name,
    required String url,
  }) async {
    await _api.post('/upload/link/$type/$id', {
      'name': name,
      'url': url,
    });
  }

  Future<void> deleteFile({
    required String type,
    required String ownerId,
    required String fileId,
  }) async {
    await _api.delete('/upload/$type/$ownerId/$fileId');
  }
}
