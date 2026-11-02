/// Display formats used across the app, matching the designs exactly.
abstract final class Formatters {
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// 0.765 → "76.5%".
  static String percent(double fraction) =>
      '${(fraction * 100).toStringAsFixed(1)}%';

  /// 0.5 → "50%" (thresholds are whole numbers in the UI).
  static String percentWhole(double fraction) => '${(fraction * 100).round()}%';

  /// "09:12".
  static String time(DateTime t) => '${_two(t.hour)}:${_two(t.minute)}';

  /// "Today, 09:12" · "Yesterday, 16:40" · "27 Oct, 11:05".
  static String relativeDayTime(DateTime t, DateTime now) =>
      '${relativeDay(t, now, withYear: false)}, ${time(t)}';

  /// Inline form for sentences: "today 08:55", "yesterday 16:40".
  static String inlineDayTime(DateTime t, DateTime now) =>
      '${relativeDay(t, now).toLowerCase()} ${time(t)}';

  /// "Today" · "Yesterday" · "27 Oct 2026" (or "27 Oct" without the year).
  static String relativeDay(DateTime t, DateTime now, {bool withYear = true}) {
    final d = DateTime(t.year, t.month, t.day);
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    final base = '${t.day} ${_months[t.month - 1]}';
    return withYear ? '$base ${t.year}' : base;
  }

  /// "29 Oct 2026".
  static String date(DateTime t) =>
      '${t.day} ${_months[t.month - 1]} ${t.year}';

  /// 9437184 → "9.0 MB".
  static String megabytes(int bytes) =>
      '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';

  /// "3.8 of 9.1 MB".
  static String megabytesOf(int done, int total) =>
      '${(done / (1024 * 1024)).toStringAsFixed(1)} of ${megabytes(total)}';

  /// 1.9 → "1.9 ms".
  static String millis(double ms) => '${ms.toStringAsFixed(1)} ms';

  /// sha256 → "83bb8785…c969b7b".
  static String shortSha(String sha) => sha.length <= 15
      ? sha
      : '${sha.substring(0, 8)}…${sha.substring(sha.length - 7)}';

  static String _two(int n) => n.toString().padLeft(2, '0');
}
