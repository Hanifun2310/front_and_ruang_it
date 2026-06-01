import 'dart:convert';
import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../routes/app_routes.dart';
import 'like_sync_service.dart';

class AuthService extends GetxService {
  final _storage = const FlutterSecureStorage();
  
  final RxBool isLoggedIn = false.obs;

  String? _token;
  Map<String, dynamic>? _currentUser;

  Future<void> initStorage() async {
    _token = await _storage.read(key: 'token');
    final userString = await _storage.read(key: 'user');
    
    if (userString != null && userString.isNotEmpty) {
      try {
        _currentUser = jsonDecode(userString);
      } catch (_) {}
    }

    if (_token != null && _token!.isNotEmpty) {
      isLoggedIn.value = true;
    }
  }

  Future<void> saveSession(String token, Map<String, dynamic> userData) async {
    _token = token;
    _currentUser = userData;
    await _storage.write(key: 'token', value: token);
    await _storage.write(key: 'user', value: jsonEncode(userData));
    isLoggedIn.value = true;
  }

  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    await _storage.delete(key: 'token');
    await _storage.delete(key: 'user');
    isLoggedIn.value = false;
    
    try {
      if (Get.isRegistered<LikeSyncService>()) {
        Get.find<LikeSyncService>().clearAll();
      }
    } catch (_) {}
    
    Get.offAllNamed(Routes.DASHBOARD);
  }

  String? get token => _token;
  Map<String, dynamic>? get currentUser => _currentUser;
}
