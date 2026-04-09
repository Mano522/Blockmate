import '../models/app_user.dart';
import 'api_client.dart';

class AuthService {
  AuthService(this._api);

  final ApiClient _api;

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final data = await _api.post('/auth/login', {
      'email': email,
      'password': password,
    });
    return Map<String, dynamic>.from(data as Map);
  }

  Future<Map<String, dynamic>> signup({
    required String name,
    required String dob,
    required String email,
    required String password,
  }) async {
    final data = await _api.post('/auth/signup', {
      'name': name,
      'dob': dob,
      'email': email,
      'password': password,
    });
    return Map<String, dynamic>.from(data as Map);
  }

  Future<String> forgotPassword(String email) async {
    final data = await _api.post('/auth/forgot-password', {'email': email});
    return (data as Map)['message']?.toString() ?? 'OTP sent';
  }

  Future<String> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final data = await _api.post('/auth/reset-password', {
      'email': email,
      'otp': otp,
      'newPassword': newPassword,
    });
    return (data as Map)['message']?.toString() ?? 'Password reset successful';
  }

  Future<AppUser> fetchProfile() async {
    final data = await _api.get('/auth/profile');
    return AppUser.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String email,
    String? password,
  }) async {
    final body = {'name': name, 'email': email};
    if (password != null && password.trim().isNotEmpty) {
      body['password'] = password;
    }
    final data = await _api.put('/auth/profile', body);
    return Map<String, dynamic>.from(data as Map);
  }

  Future<String> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final data = await _api.put('/auth/change-password', {
      'oldPassword': oldPassword,
      'newPassword': newPassword,
    });
    return (data as Map)['message']?.toString() ?? 'Password updated successfully';
  }
}
