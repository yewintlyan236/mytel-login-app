import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/account_summary.dart';

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

  // ---------------------------------------------------- balance / min / MB

  static final RegExp _uuid = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');

  /// Finds the account UUID inside one item of the account list.
  String? _findId(Map m) {
    for (final k in ['id', 'accountId', 'account_id', 'subscriberId', 'subId']) {
      final v = m[k];
      if (v is String && _uuid.hasMatch(v)) return v;
    }
    for (final v in m.values) {
      if (v is String && _uuid.hasMatch(v)) return v;
    }
    for (final v in m.values) {
      if (v is Map) {
        final r = _findId(v);
        if (r != null) return r;
      }
    }
    return null;
  }

  Future<Map<String, dynamic>?> _getBalanceDetail(String id) async {
    try {
      final response = await _dio.get(
        '/account-detail/api/v1.1/individual/$id/account-main',
        queryParameters: {'language': 'EN'},
      );
      final body = response.data;
      if (body is Map && body['errorCode'] == 0 && body['result'] is Map) {
        return Map<String, dynamic>.from(body['result']);
      }
    } catch (_) {}
    return null;
  }

  /// Every number on the login with Balance, Promo, Minutes and Data (MB).
  Future<ApiResult<List<AccountSummary>>> getAccountSummaries(
      String phoneNumber) async {
    final res = await getAccountDetails(phoneNumber);
    if (!res.ok) {
      return ApiResult(
          ok: false, message: res.message, unauthorized: res.unauthorized);
    }

    final list = (res.data?['result'] as List?) ?? const [];
    final summaries = await Future.wait(list.map((item) async {
      final map =
          item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{};
      final msisdn = (map['msisdn'] ?? phoneNumber).toString();
      final id = _findId(map);

      Stat? main = Stat.from(map['mainBalance']?['main']);
      Stat? promo, voice, data;

      if (id != null) {
        final d = await _getBalanceDetail(id);
        if (d != null) {
          main = Stat.from(d['main']) ?? main;
          promo = Stat.from(d['promo']);
          voice = Stat.from(d['voice']);
          data = Stat.from(d['data']);
        }
      }
      return AccountSummary(
        msisdn: msisdn,
        id: id,
        main: main,
        promo: promo,
        voice: voice,
        data: data,
      );
    }).toList());

    return ApiResult(ok: true, data: summaries);
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
