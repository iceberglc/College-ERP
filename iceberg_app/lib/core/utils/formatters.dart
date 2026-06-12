import 'package:intl/intl.dart';

String fmtDate(String? iso) {
  if (iso == null || iso.isEmpty) return '—';
  try {
    return DateFormat('d MMM yyyy').format(DateTime.parse(iso));
  } catch (_) {
    return iso;
  }
}

String fmtPercent(dynamic value) {
  if (value == null) return '—';
  final d = (value is num) ? value.toDouble() : double.tryParse(value.toString());
  if (d == null) return '—';
  return '${d.toStringAsFixed(1)}%';
}

String fmtNum(dynamic value) {
  if (value == null) return '—';
  return value.toString();
}
