class Stat {
  final num? amount;
  final String unit;
  const Stat(this.amount, this.unit);

  static Stat? from(dynamic m) {
    if (m is! Map) return null;
    final a = m['amount'];
    return Stat(
      a is num ? a : num.tryParse('$a'),
      (m['unit'] ?? '').toString(),
    );
  }
}

/// One phone number with Balance / Promo / Minutes / Data.
class AccountSummary {
  final String msisdn;
  final String? id;
  final Stat? main;
  final Stat? promo;
  final Stat? voice;
  final Stat? data;

  const AccountSummary({
    required this.msisdn,
    this.id,
    this.main,
    this.promo,
    this.voice,
    this.data,
  });
}

/// Loyalty points of one number (from the loyalty "inquiry" API).
class PointsInfo {
  final int points;
  final int exchanged; // points already exchanged this month
  final int monthlyLimit;
  final String? rankName;

  const PointsInfo({
    required this.points,
    required this.exchanged,
    required this.monthlyLimit,
    this.rankName,
  });

  int get remainingThisMonth =>
      (monthlyLimit - exchanged).clamp(0, monthlyLimit);
}
