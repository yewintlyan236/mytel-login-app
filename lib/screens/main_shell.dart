import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/gradient_scaffold.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'youtube_screen.dart';

/// Main app frame: gradient header + side menu (Drawer).
class MainShell extends StatefulWidget {
  final String phoneNumber;
  const MainShell({super.key, required this.phoneNumber});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _titles = ['Mytel Account', 'YouTube Package'];

  Future<void> _confirmLogout() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout'),
        content: const Text('Account ကနေ ထွက်မှာ သေချာပါသလား?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('မထွက်ပါ')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('ထွက်မည်')),
        ],
      ),
    );
    if (yes == true) await _logoutNow();
  }

  /// Clears the saved session and goes to Login. Only called from user actions.
  Future<void> _logoutNow() async {
    await ApiService().logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _select(int i) {
    Navigator.pop(context); // close drawer
    setState(() => _index = i);
  }

  Widget _drawer() {
    Widget item(IconData icon, String text, int i) => ListTile(
          leading: Icon(icon,
              color: _index == i ? AppColors.primary : Colors.black54),
          title: Text(text,
              style: TextStyle(
                  fontWeight:
                      _index == i ? FontWeight.w800 : FontWeight.w500,
                  color: _index == i ? AppColors.primary : Colors.black87)),
          selected: _index == i,
          selectedTileColor: AppColors.primary.withOpacity(0.08),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          onTap: () => _select(i),
        );

    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
                20, MediaQuery.of(context).padding.top + 24, 20, 24),
            decoration: const BoxDecoration(gradient: AppColors.gradient),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 34, color: AppColors.primary),
                ),
                const SizedBox(height: 14),
                const Text('Mytel',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(widget.phoneNumber,
                    style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                item(Icons.home_rounded, 'Home', 0),
                const SizedBox(height: 4),
                item(Icons.play_circle_fill_rounded, 'YouTube ဝယ်ရန်', 1),
              ],
            ),
          ),
          const Spacer(),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.red),
              title: const Text('Logout',
                  style: TextStyle(
                      color: Colors.red, fontWeight: FontWeight.w700)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              onTap: () {
                Navigator.pop(context);
                _confirmLogout();
              },
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(phoneNumber: widget.phoneNumber, onRelogin: _logoutNow),
      YoutubeScreen(phoneNumber: widget.phoneNumber, onRelogin: _logoutNow),
    ];

    return GradientScaffold(
      title: _titles[_index],
      drawer: _drawer(),
      body: pages[_index],
    );
  }
}
