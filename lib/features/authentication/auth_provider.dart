import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/storage/secure_storage.dart';

// Provide ApiClient
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

abstract class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthenticatedState extends AuthState {
  final String userId;
  final String userName;
  final String role;
  const AuthenticatedState({required this.userId, required this.userName, required this.role});
}

class AuthErrorState extends AuthState {
  final String message;
  const AuthErrorState(this.message);
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    _checkStatus();
    return const AuthInitial();
  }

  Future<void> _checkStatus() async {
    final token = await SecureStorage.getAccessToken();
    if (token != null) {
      final userId = await SecureStorage.getUserId() ?? '';
      final userName = await SecureStorage.getUserName() ?? '';
      state = AuthenticatedState(userId: userId, userName: userName, role: 'FamilyAdmin');
    }
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String mobileNumber,
    required String password,
    required String country,
    required String preferredLanguage,
  }) async {
    state = const AuthLoading();
    try {
      final client = ref.read(apiClientProvider);
      final response = await client.dio.post('/api/auth/register', data: {
        'fullName': fullName,
        'email': email,
        'mobileNumber': mobileNumber,
        'password': password,
        'country': country,
        'preferredLanguage': preferredLanguage,
      });

      if (response.data['success'] == true) {
        final data = response.data['data'];
        await SecureStorage.saveTokens(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
          userId: data['user']['userId'],
          userName: data['user']['name'],
        );
        state = AuthenticatedState(
          userId: data['user']['userId'],
          userName: data['user']['name'],
          role: data['user']['role'],
        );
        return true;
      } else {
        final List<dynamic>? errors = response.data['errors'];
        final errorMsg = errors != null && errors.isNotEmpty ? errors.first.toString() : 'Registration failed.';
        state = AuthErrorState(errorMsg);
        return false;
      }
    } catch (e) {
      state = AuthErrorState(e.toString());
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    state = const AuthLoading();
    try {
      final client = ref.read(apiClientProvider);
      final response = await client.dio.post('/api/auth/login', data: {
        'email': email,
        'password': password,
      });

      if (response.data['success'] == true) {
        final data = response.data['data'];
        await SecureStorage.saveTokens(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
          userId: data['user']['userId'],
          userName: data['user']['name'],
        );
        state = AuthenticatedState(
          userId: data['user']['userId'],
          userName: data['user']['name'],
          role: data['user']['role'],
        );
        return true;
      } else {
        final List<dynamic>? errors = response.data['errors'];
        final errorMsg = errors != null && errors.isNotEmpty ? errors.first.toString() : 'Login failed.';
        state = AuthErrorState(errorMsg);
        return false;
      }
    } catch (e) {
      state = AuthErrorState(e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    await SecureStorage.clearAll();
    state = const AuthInitial();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
