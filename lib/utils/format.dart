/// Short relative time: "now", "5m", "3h", "2d", or "12/10".
String timeAgo(DateTime? t) {
  if (t == null) return '';
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'now';
  if (d.inMinutes < 60) return '${d.inMinutes}m';
  if (d.inHours < 24) return '${d.inHours}h';
  if (d.inDays < 7) return '${d.inDays}d';
  return '${t.day}/${t.month}';
}

String clockTime(DateTime? t) {
  if (t == null) return '';
  final h = t.hour.toString().padLeft(2, '0');
  final m = t.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

const _wd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _mo = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// "Sat, 24 Oct"
String fmtDate(DateTime d) => '${_wd[d.weekday - 1]}, ${d.day} ${_mo[d.month - 1]}';

/// "16:00–17:00"
String fmtRange(DateTime s, DateTime e) => '${clockTime(s)}–${clockTime(e)}';
