import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/gradient_button.dart';

class YoutubeScreen extends StatefulWidget {
  final String phoneNumber;

  /// Called ONLY when the user taps "Login ပြန်ဝင်ရန်" after the session expired.
  final VoidCallback onRelogin;

  const YoutubeScreen(
      {super.key, required this.phoneNumber, required this.onRelogin});

  @override
  State<YoutubeScreen> createState() => _YoutubeScreenState();
}

class _YoutubeScreenState extends State<YoutubeScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  Future<void> _buy() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('YouTube Package ဝယ်မည်လား?'),
        content: const Text(
            'YouTube Data 1.5GB ကို ၉၉၉ ကျပ်ဖြင့် ဝယ်ယူမည်ဖြစ်ပြီး လက်ကျန်ငွေမှ နှုတ်ယူပါမည်။'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('မဝယ်ပါ')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('ဝယ်မည်')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isLoading = true);
    final res = await _apiService.buyYoutubePackage(widget.phoneNumber);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res.unauthorized) {
      _showResult(
        ok: false,
        message: 'Session ကုန်သွားပါပြီ။ Login ပြန်ဝင်ပါ။',
        relogin: true,
      );
      return;
    }

    _showResult(
      ok: res.ok,
      message: res.message ??
          (res.ok ? 'ဝယ်ယူမှု အောင်မြင်ပါသည်' : 'ဝယ်ယူမှု မအောင်မြင်ပါ'),
    );
  }

  void _showResult({
    required bool ok,
    required String message,
    bool relogin = false,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Icon(
          ok ? Icons.check_circle : Icons.error,
          size: 52,
          color: ok ? Colors.green : Colors.red,
        ),
        title: Text(ok ? 'အောင်မြင်ပါသည်' : 'မအောင်မြင်ပါ'),
        content: Text(message),
        actions: [
          if (relogin)
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                widget.onRelogin();
              },
              child: const Text('Login ပြန်ဝင်ရန်'),
            ),
          FilledButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: AppColors.youtubeGradient,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.play_arrow_rounded,
                        color: Colors.red, size: 30),
                  ),
                  const SizedBox(width: 12),
                  const Text('YouTube Data',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 26),
              const Text('1.5 GB',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 46,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              const Text('၃ ရက် သက်တမ်း',
                  style: TextStyle(color: Colors.white70, fontSize: 15)),
              const SizedBox(height: 22),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text('၉၉၉ ကျပ်',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _row(Icons.phone_android, 'ဖုန်းနံပါတ်',
                    ApiService.toMsisdn(widget.phoneNumber)),
                const Divider(height: 26),
                _row(Icons.account_balance_wallet_outlined, 'ငွေပေးချေမှု',
                    'Main Balance မှ နှုတ်မည်'),
                const Divider(height: 26),
                _row(Icons.flight_takeoff, 'အသုံးပြုရန်',
                    'Airplane mode on/off လုပ်ပြီး VPN ဖြုတ်ပါ'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        GradientButton(
          text: 'YouTube Package ဝယ်ရန်',
          icon: Icons.shopping_cart_checkout,
          gradient: AppColors.youtubeGradient,
          loading: _isLoading,
          onPressed: _buy,
        ),
      ],
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(color: Colors.black45, fontSize: 12)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ],
    );
  }
}
