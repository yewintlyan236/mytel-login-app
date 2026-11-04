import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Simple result wrapper so screens can show server messages
/// and react to an expired session WITHOUT the app logging out by itself.
class ApiResult<T> {
  final bool ok;
  final T? data;
  final String? message;
  final bool unauthorized;

  const ApiResult({
    required this.ok,
    this.data,
    this.message,
    this.unauthorized = false,
  });
}

class ApiService {
  // Singleton: every screen shares the same session.
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio _dio;
  static const String _tokenKey = 'mytel_access_token';
  static const String _phoneKey = 'mytel_phone_number';

  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: 'https://apis.mytel.com.mm',
      headers: {
        'Content-Type': 'application/json',
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Mobile Safari/537.36',
        'Referer': 'https://mytel.com.mm/#/',
      },
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ));
  }

  // ---------------------------------------------------------------- session

  Future<void> saveSession(String token, String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_phoneKey, phone);
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
    return token;
  }

  Future<String?> getSavedPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_phoneKey);
  }

  /// Returns the saved phone number if a session exists, otherwise null.
  Future<String?> restoreSession() async {
    final token = await getToken();
    final phone = await getSavedPhone();
    if (token == null || phone == null) return null;
    return phone;
  }

  /// The ONLY place where the session is cleared.
  /// Called only when the user taps Logout and confirms.
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_phoneKey);
    _dio.options.headers.remove('Authorization');
  }

  // ------------------------------------------------------------------ utils

  /// 09675447420 / 9675447420 / +959675447420  ->  +959675447420
  static String toMsisdn(String input) {
    var s = input.replaceAll(RegExp(r'[\s\-+]'), '');
    if (s.startsWith('95') && s.length >= 11) s = s.substring(2);
    if (s.startsWith('0')) s = s.substring(1);
    return '+95$s';
  }

  String _errorMessage(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        return 'အင်တာနက် ချိတ်ဆက်မှု မရှိပါ';
      }
    }
    return 'အမှားတစ်ခု ဖြစ်ပေါ်ခဲ့ပါသည်';
  }

  bool _isUnauthorized(Object e) =>
      e is DioException && e.response?.statusCode == 401;

  // ------------------------------------------------------------------- auth

  Future<bool> sendOtp(String phoneNumber) async {
    try {
      final response = await _dio.get(
        '/myid/authen/v1.0/login/method/otp/get-otp',
        queryParameters: {'phoneNumber': phoneNumber},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> validateOtp(String phoneNumber, String otp) async {
    try {
      final response = await _dio.post(
        '/myid/authen/v1.0/login/method/otp/validate-otp',
        data: {
          'phoneNumber': phoneNumber,
          'password': otp,
          'version': '8.1',
        },
      );

      if (response.statusCode == 200 && response.data['errorCode'] == 200) {
        final token = response.data['result']['access_token'];
        await saveSession(token, phoneNumber);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ---------------------------------------------------------------- account

  Future<ApiResult<Map<String, dynamic>>> getAccountDetails(
      String phoneNumber) async {
    try {
      final token = await getToken();
      if (token == null) {
        return const ApiResult(ok: false, unauthorized: true);
      }

      final response = await _dio.get(
        '/account-detail/api/v1.2/individual/account-main',
        queryParameters: {'isdn': phoneNumber, 'language': 'MU'},
      );

      if (response.statusCode == 200 && response.data is Map) {
        return ApiResult(
            ok: true, data: Map<String, dynamic>.from(response.data));
      }
      return const ApiResult(ok: false);
    } catch (e) {
      return ApiResult(
        ok: false,
        message: _errorMessage(e),
        unauthorized: _isUnauthorized(e),
      );
    }
  }

  // ---------------------------------------------------------------- YouTube

  /// YouTube Data 1.5GB (GG3) - 999 Ks
  Future<ApiResult<void>> buyYoutubePackage(String phoneNumber) async {
    try {
      final token = await getToken();
      if (token == null) {
        return const ApiResult(ok: false, unauthorized: true);
      }

      final response = await _dio.post(
        '/csm/v1.0/api/vas-package/GG3/register',
        data: {'msisdn': toMsisdn(phoneNumber), 'isRenew': false},
      );

      final body = response.data;
      final code = body is Map ? body['errorCode'] : null;
      final msg = body is Map ? body['message'] as String? : null;

      // errorCode 0 = success, 2 = balance not enough, etc.
      return ApiResult(ok: code == 0, message: msg);
    } catch (e) {
      return ApiResult(
        ok: false,
        message: _errorMessage(e),
        unauthorized: _isUnauthorized(e),
      );
    }
  }
}
