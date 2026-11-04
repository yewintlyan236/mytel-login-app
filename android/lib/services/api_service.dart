import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final Dio _dio;
  static const String _tokenKey = 'mytel_access_token';

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: 'https://apis.mytel.com.mm',
      headers: {
        'Content-Type': 'application/json',
        // Log တွေအတိုင်း ထည့်ပေးထားပါသည်
        'User-Agent': 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Mobile Safari/537.36',
        'Referer': 'https://mytel.com.mm/#/',
        // API Key လိုအပ်ရင် အောက်ပါအတိုင်း ထည့်နိုင်ပါသည်
        // 'X-API-Key': 'YOUR_API_KEY_HERE', 
      },
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
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
        await saveToken(token);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> getAccountDetails(String phoneNumber) async {
    try {
      final token = await getToken();
      if (token == null) return null;

      final response = await _dio.get(
        '/account-detail/api/v1.2/individual/account-main',
        queryParameters: {'isdn': phoneNumber, 'language': 'MU'},
      );

      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
