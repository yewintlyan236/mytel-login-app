import 'package:flutter/material.dart';
import '../models/account_summary.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/account_card.dart';

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
  List<AccountSummary> _accounts = const [];
  bool _isLoading = true;
  int _tick = 0; // changes on pull-to-refresh so Points reload too
  bool _sessionExpired = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAccountDetails();
  }

  Future<void> _fetchAccountDetails({bool silent = false}) async {
    if (mounted && !silent) setState(() => _isLoading = true);
    final res = await _apiService.getAccountSummaries(widget.phoneNumber);
    if (!mounted) return;
    setState(() {
      _accounts = res.data ?? const [];
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

    final accounts = _accounts;

    return RefreshIndicator(
      onRefresh: () {
        _tick++;
        return _fetchAccountDetails(silent: true);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          if (_sessionExpired) _expiredCard(),
          if (!_sessionExpired && accounts.isEmpty) _emptyCard(),
          for (final account in accounts) ...[
            AccountCard(
              key: ValueKey('${account.msisdn}#$_tick'),
              summary: account,
              onChanged: () => _fetchAccountDetails(silent: true),
            ),
            const SizedBox(height: 16),
          ],
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
