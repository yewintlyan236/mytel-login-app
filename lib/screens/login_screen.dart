import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/gradient_button.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      _showError('ဖုန်းနံပါတ် မထည့်သေးပါ');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final isOtpSent = await _apiService.sendOtp(phone);
      if (!mounted) return;
      if (isOtpSent) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => OtpScreen(phoneNumber: phone)),
        );
      } else {
        _showError('OTP ပို့ရာတွင် အမှားရှိပါသည်');
      }
    } catch (e) {
      _showError('Connection Error');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.gradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.sim_card,
                        size: 56, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  const Text('Mytel',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  const Text('ဖုန်းနံပါတ်ဖြင့် ဝင်ရောက်ပါ',
                      style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 32),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('Login',
                              style: TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 18),
                          TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Phone Number',
                              prefixIcon: Icon(Icons.phone_android),
                              prefixText: '+95 ',
                            ),
                          ),
                          const SizedBox(height: 20),
                          GradientButton(
                            text: 'Send OTP',
                            icon: Icons.sms_outlined,
                            loading: _isLoading,
                            onPressed: _handleSendOtp,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
