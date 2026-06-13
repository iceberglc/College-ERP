import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api/api_client.dart';

// ─── User model ──────────────────────────────────────────────────────────────
class IceUser {
  final int id;
  final String email;
  final String loginId;
  final String firstName;
  final String lastName;
  final String userType; // "1" admin, "2" staff, "3" student
  final String? profilePicUrl;
  final String avatar; // emoji avatar ('' when unset)
  final Map<String, dynamic>? roleProfile;

  const IceUser({
    required this.id,
    required this.email,
    required this.loginId,
    required this.firstName,
    required this.lastName,
    required this.userType,
    this.profilePicUrl,
    this.avatar = '',
    this.roleProfile,
  });

  String get fullName => '$firstName $lastName'.trim();
  bool get isAdmin => userType == '1';
  bool get isStaff => userType == '2';
  bool get isStudent => userType == '3';
  bool get isSuperAdmin => isAdmin && (roleProfile?['is_super_admin'] == true);
  List<int> get branchIds =>
      isAdmin ? ((roleProfile?['branch_ids'] as List?)?.cast<int>() ?? []) : [];

  factory IceUser.fromJson(Map<String, dynamic> j) => IceUser(
    id: j['id'],
    email: j['email'] ?? '',
    loginId: j['login_id'] ?? '',
    firstName: j['first_name'] ?? '',
    lastName: j['last_name'] ?? '',
    userType: j['user_type'].toString(),
    profilePicUrl: j['profile_pic_url'],
    avatar: j['avatar'] ?? '',
    roleProfile: j['role_profile'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'login_id': loginId,
    'first_name': firstName,
    'last_name': lastName,
    'user_type': userType,
    'profile_pic_url': profilePicUrl,
    'avatar': avatar,
    'role_profile': roleProfile,
  };
}

// ─── Auth state ───────────────────────────────────────────────────────────────
enum AuthStatus { loading, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final IceUser? user;
  final String? error;

  const AuthState({required this.status, this.user, this.error});

  factory AuthState.loading() => const AuthState(status: AuthStatus.loading);
  factory AuthState.unauth([String? e]) =>
      AuthState(status: AuthStatus.unauthenticated, error: e);
  factory AuthState.auth(IceUser u) =>
      AuthState(status: AuthStatus.authenticated, user: u);
}

// ─── Provider ────────────────────────────────────────────────────────────────
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState.loading()) {
    // When a token refresh fails (expired/blacklisted), drop to login cleanly
    // instead of leaving the user stuck on an error screen.
    _api.onSessionExpired = _handleSessionExpired;
    _init();
  }

  final _storage = const FlutterSecureStorage();
  final _api = ApiClient.instance;

  Future<void> _init() async {
    // Prime the in-memory token cache so the very first authenticated request
    // is reliably signed (web secure-storage reads can be flaky).
    await _api.loadTokens();
    final cached = await _storage.read(key: 'user_json');
    final token = await _api.accessToken;
    if (cached != null && token != null) {
      try {
        state = AuthState.auth(IceUser.fromJson(jsonDecode(cached)));
        return;
      } catch (_) {}
    }
    state = AuthState.unauth();
  }

  void _handleSessionExpired() {
    _storage.delete(key: 'user_json');
    state = AuthState.unauth('Your session expired. Please sign in again.');
  }

  /// Login with email OR login_id + password.
  Future<String?> login(String identifier, String password) async {
    try {
      final res = await _api.dio.post(
        '/auth/login/',
        data: {'identifier': identifier, 'password': password},
      );
      final data = res.data as Map<String, dynamic>;
      await _api.saveTokens(data['access'], data['refresh']);
      final user = IceUser.fromJson(data['user']);
      await _storage.write(key: 'user_json', value: jsonEncode(user.toJson()));
      state = AuthState.auth(user);
      return null; // success
    } on Exception catch (e) {
      String msg = 'Login failed. Check your credentials.';
      if (e.toString().contains('401')) msg = 'Invalid ID or password.';
      if (e.toString().contains('403')) msg = 'Account locked or disabled.';
      return msg;
    }
  }

  Future<void> logout() async {
    try {
      final refresh = await _storage.read(key: 'refresh_token');
      if (refresh != null) {
        await _api.dio.post('/auth/logout/', data: {'refresh': refresh});
      }
    } catch (_) {}
    await _api.clearTokens();
    await _storage.delete(key: 'user_json');
    state = AuthState.unauth();
  }

  void updateUser(IceUser user) {
    _storage.write(key: 'user_json', value: jsonEncode(user.toJson()));
    state = AuthState.auth(user);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (_) => AuthNotifier(),
);
