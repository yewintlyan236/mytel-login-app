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
