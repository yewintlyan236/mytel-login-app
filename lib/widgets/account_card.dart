import 'package:flutter/material.dart';
import '../models/account_summary.dart';
import '../theme.dart';
import '../utils/format.dart';

/// Big dark card: number, Balance, Minutes and Data (MB).
class AccountCard extends StatelessWidget {
  final AccountSummary summary;
  const AccountCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final s = summary;
    final promoAmount = s.promo?.amount;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2B2B45), Color(0xFF1B1B2F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.phone_android,
                    color: Colors.white70, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(s.msisdn,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1)),
              ),
              if (promoAmount != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Promo ${fmtNum(promoAmount)} ${s.promo?.unit ?? 'Ks'}',
                    style: const TextStyle(
                        color: Color(0xFFFFB38A),
                        fontSize: 12,
                        fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 22),
          const Text('Balance',
              style: TextStyle(color: Colors.white60, fontSize: 13)),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(fmtNum(s.main?.amount),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      height: 1.1,
                      fontWeight: FontWeight.w800)),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  (s.main?.unit.isNotEmpty ?? false) ? s.main!.unit : 'Ks',
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 17,
                      fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _Tile(
                  icon: Icons.call_rounded,
                  color: const Color(0xFF3DDC84),
                  label: 'မိနစ်',
                  value: fmtNum(s.voice?.amount),
                  unit: 'min',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Tile(
                  icon: Icons.network_cell_rounded,
                  color: const Color(0xFF4FC3F7),
                  label: 'Data',
                  value: fmtNum(s.data?.amount),
                  unit: 'MB',
                  hint: mbToGbHint(s.data?.amount),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String unit;
  final String? hint;

  const _Tile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.unit,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(color: Colors.white60, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(width: 5),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(unit,
                    style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          if (hint != null) ...[
            const SizedBox(height: 2),
            Text(hint!,
                style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ],
        ],
      ),
    );
  }
}

/// Compact white strip: Balance | Minutes | MB  (used on the YouTube page).
class MiniStats extends StatelessWidget {
  final AccountSummary? summary;
  final bool loading;
  const MiniStats({super.key, required this.summary, this.loading = false});

  @override
  Widget build(BuildContext context) {
    final s = summary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: loading
            ? const SizedBox(
                height: 62,
                child: Center(
                    child: SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(strokeWidth: 3))),
              )
            : Row(
                children: [
                  _item(Icons.account_balance_wallet_rounded,
                      AppColors.primary, 'Balance', fmtNum(s?.main?.amount), 'Ks'),
                  _divider(),
                  _item(Icons.call_rounded, const Color(0xFF2E9E5B), 'မိနစ်',
                      fmtNum(s?.voice?.amount), 'min'),
                  _divider(),
                  _item(Icons.network_cell_rounded, const Color(0xFF1E88E5),
                      'Data', fmtNum(s?.data?.amount), 'MB'),
                ],
              ),
      ),
    );
  }

  Widget _divider() =>
      Container(width: 1, height: 52, color: Colors.black12);

  Widget _item(
      IconData icon, Color color, String label, String value, String unit) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800)),
          ),
          Text('$label ($unit)',
              style: const TextStyle(color: Colors.black45, fontSize: 11)),
        ],
      ),
    );
  }
}
