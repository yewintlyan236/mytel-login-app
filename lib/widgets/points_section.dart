import 'package:flutter/material.dart';
import '../models/account_summary.dart';
import '../services/api_service.dart';
import '../utils/format.dart';
import '../widgets/gradient_button.dart';

const Color _gold = Color(0xFFFFC107);

/// Shows loyalty points of one number and a button:
/// 1000 Point = 2750 MB.
class PointsSection extends StatefulWidget {
  final String msisdn;

  /// Called after a successful exchange so the MB shown above can refresh.
  final VoidCallback? onExchanged;

  const PointsSection({super.key, required this.msisdn, this.onExchanged});

  @override
  State<PointsSection> createState() => _PointsSectionState();
}

class _PointsSectionState extends State<PointsSection> {
  final ApiService _api = ApiService();
  PointsInfo? _info;
  bool _loading = true;
  bool _exchanging = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    final res = await _api.getPoints(widget.msisdn);
    if (!mounted) return;
    setState(() {
      _info = res.data;
      _error = res.ok ? null : (res.message ?? 'Points ယူ၍မရပါ');
      _loading = false;
    });
  }

  bool get _canExchange {
    final i = _info;
    if (i == null) return false;
    return i.points >= ApiService.pointsPerExchange &&
        i.remainingThisMonth >= ApiService.pointsPerExchange;
  }

  Future<void> _exchange() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Point လဲမလား?'),
        content: Text(
            '${widget.msisdn} အတွက် ${ApiService.pointsPerExchange} Point ကို 2750 MB နဲ့ လဲမှာဖြစ်ပါတယ်။'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('မလဲပါ')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('လဲမည်')),
        ],
      ),
    );
    if (yes != true) return;

    setState(() => _exchanging = true);
    final res = await _api.exchangePointsForData(widget.msisdn);
    if (!mounted) return;
    setState(() => _exchanging = false);

    final msg = res.unauthorized
        ? 'Session ကုန်သွားပါပြီ။ Login ပြန်ဝင်ပါ။'
        : res.ok
            ? '2750 MB လဲလှယ်မှု အောင်မြင်ပါသည်'
            : (res.message ?? 'လဲလှယ်မှု မအောင်မြင်ပါ');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: res.ok ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );

    if (res.ok) {
      await _load();
      widget.onExchanged?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final i = _info;
    final limit = i?.monthlyLimit ?? 0;
    final progress = (i == null || limit == 0)
        ? 0.0
        : (i.exchanged / limit).clamp(0.0, 1.0);

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
                  color: _gold.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.stars_rounded, color: _gold, size: 18),
              ),
              const SizedBox(width: 8),
              const Text('Points',
                  style: TextStyle(color: Colors.white60, fontSize: 13)),
              const Spacer(),
              if (_loading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.2, color: _gold),
                )
              else if (i != null)
                Text(fmtNum(i.points),
                    style: const TextStyle(
                        color: _gold,
                        fontSize: 22,
                        fontWeight: FontWeight.w800)),
            ],
          ),
          if (i != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: Colors.white12,
                valueColor: const AlwaysStoppedAnimation(_gold),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'ယခုလ လဲပြီး ${fmtNum(i.exchanged)} / ${fmtNum(i.monthlyLimit)} Point',
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
          if (_error != null && !_loading) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _load,
              child: Text('$_error  (ပြန်စမ်းရန် နှိပ်ပါ)',
                  style:
                      const TextStyle(color: Colors.redAccent, fontSize: 12)),
            ),
          ],
          const SizedBox(height: 14),
          GradientButton(
            text: '1000 Point = 2750 MB လဲမယ်',
            icon: Icons.swap_horiz_rounded,
            gradient: const LinearGradient(
                colors: [Color(0xFFFFB300), Color(0xFFFF6D00)]),
            loading: _exchanging,
            onPressed: _canExchange ? _exchange : null,
          ),
        ],
      ),
    );
  }
}
