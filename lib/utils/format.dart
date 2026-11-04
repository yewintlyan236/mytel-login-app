/// 2670 -> "2,670", 20.5 -> "20.50", null -> "-"
String fmtNum(num? n) {
  if (n == null) return '-';
  final isInt = n == n.roundToDouble();
  final s = isInt ? n.toInt().toString() : n.toStringAsFixed(2);
  final parts = s.split('.');
  final neg = parts[0].startsWith('-');
  final digits = neg ? parts[0].substring(1) : parts[0];
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
    buf.write(digits[i]);
  }
  final out = '${neg ? '-' : ''}$buf';
  return parts.length > 1 ? '$out.${parts[1]}' : out;
}

/// 2670 MB -> "≈ 2.61 GB" (only when >= 1 GB)
String? mbToGbHint(num? mb) {
  if (mb == null || mb < 1024) return null;
  return '≈ ${(mb / 1024).toStringAsFixed(2)} GB';
}
