import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme.dart';

class HomeScreen extends StatefulWidget {
  final String phoneNumber;

  /// Called ONLY when the user taps "Login ပြန်ဝင်ရန်" after the session expired.
  final VoidCallback onRelogin;

  const HomeScreen(
      {super.key, required this.phoneNumber, required this.onRelogin});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _accountData;
  bool _isLoading = true;
  bool _sessionExpired = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAccountDetails();
  }

  Future<void> _fetchAccountDetails() async {
    if (mounted) setState(() => _isLoading = true);
    final res = await _apiService.getAccountDetails(widget.phoneNumber);
    if (!mounted) return;
    setState(() {
      _accountData = res.data;
      _sessionExpired = res.unauthorized;
      _error = res.ok ? null : res.message;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.white));
    }

    final accounts = (_accountData?['result'] as List?) ?? const [];

    return RefreshIndicator(
      onRefresh: _fetchAccountDetails,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          if (_sessionExpired) _expiredCard(),
          if (!_sessionExpired && accounts.isEmpty) _emptyCard(),
          for (final account in accounts) ...[
            _balanceCard(account),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _balanceCard(dynamic account) {
    final main = account?['mainBalance']?['main'];
    final msisdn = account?['msisdn'] ?? widget.phoneNumber;
    final amount = main?['amount']?.toString() ?? '-';
    final unit = main?['unit']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2B2B45), Color(0xFF1B1B2F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.phone_android, color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              Text('$msisdn',
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 22),
          const Text('Main Balance',
              style: TextStyle(color: Colors.white60, fontSize: 13)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight: FontWeight.w800)),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Text(unit,
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _expiredCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.info_outline, size: 40, color: AppColors.primary),
            const SizedBox(height: 10),
            const Text('Session ကုန်သွားပါပြီ',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text('Login ပြန်ဝင်မှ အချက်အလက်များ ကြည့်နိုင်ပါမည်။',
                textAlign: TextAlign.center),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: widget.onRelogin,
              icon: const Icon(Icons.login),
              label: const Text('Login ပြန်ဝင်ရန်'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.search_off, size: 40, color: Colors.black38),
            const SizedBox(height: 10),
            Text(_error ?? 'Data not found',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            const Text('အောက်သို့ဆွဲ၍ ပြန်စမ်းကြည့်ပါ',
                style: TextStyle(color: Colors.black45)),
          ],
        ),
      ),
    );
  }
}
