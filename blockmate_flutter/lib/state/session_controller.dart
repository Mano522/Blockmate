import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import '../models/app_user.dart';
import '../services/api_client.dart';

class SessionController extends ChangeNotifier {
  SessionController(this._apiClient);

  final ApiClient _apiClient;

  bool _initialized = false;
  AppUser? _user;
  String? _token;
  Map<String, dynamic> _rawData = {};

  bool get initialized => _initialized;
  AppUser? get user => _user;
  String? get token => _token;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppConstants.blogDataKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        _applySession(map, notify: false);
      } catch (_) {
        await prefs.remove(AppConstants.blogDataKey);
      }
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> saveSession(Map<String, dynamic> data) async {
    _applySession(data);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.blogDataKey, jsonEncode(_rawData));
  }

  Future<void> clearSession() async {
    _user = null;
    _token = null;
    _rawData = {};
    _apiClient.setToken(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.blogDataKey);
    notifyListeners();
  }

  void _applySession(Map<String, dynamic> data, {bool notify = true}) {
    _rawData = Map<String, dynamic>.from(data);
    _token = (data['token'] ?? '').toString();
    final userJson = data['user'] is Map
        ? Map<String, dynamic>.from(data['user'] as Map)
        : data;
    _user = AppUser.fromJson(userJson);
    _apiClient.setToken(_token);
    if (notify) {
      notifyListeners();
    }
  }
}
