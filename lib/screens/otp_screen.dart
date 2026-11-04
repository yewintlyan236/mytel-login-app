import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/gradient_button.dart';
import 'main_shell.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  const OtpScreen({super.key, required this.phoneNumber});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty) {
      _showError('OTP မထည့်သေးပါ');
      return;
    }

    setState(() => _isLoading = true);
    final ok = await _apiService.validateOtp(widget.phoneNumber, otp);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (ok) {
      // Clear the whole stack so Back never returns to login.
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => MainShell(phoneNumber: widget.phoneNumber),
        ),
        (route) => false,
      );
    } else {
      _showError('OTP မမှန်ပါ');
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
          child: Stack(
            children: [
              Positioned(
                left: 4,
                top: 4,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Icon(Icons.lock_outline,
                          size: 64, color: Colors.white),
                      const SizedBox(height: 12),
                      const Text('OTP ရိုက်ထည့်ပါ',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Text('OTP ပို့ထားသည့်နံပါတ်: ${widget.phoneNumber}',
                          style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 28),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(22),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextField(
                                controller: _otpController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 24,
                                    letterSpacing: 8,
                                    fontWeight: FontWeight.w700),
                                decoration: const InputDecoration(
                                  labelText: 'OTP',
                                ),
                              ),
                              const SizedBox(height: 20),
                              GradientButton(
                                text: 'Verify',
                                icon: Icons.verified_outlined,
                                loading: _isLoading,
                                onPressed: _handleVerify,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
