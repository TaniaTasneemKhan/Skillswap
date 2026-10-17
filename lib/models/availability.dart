/// A recurring weekly availability window. weekday follows DateTime.weekday
/// (1 = Monday ... 7 = Sunday); times are minutes from midnight, local time.
class AvailabilitySlot {
  final int weekday;
  final int startMin;
  final int endMin;
  const AvailabilitySlot({required this.weekday, required this.startMin, required this.endMin});

  String get label => '${fmtMinutes(startMin)}–${fmtMinutes(endMin)}';

  bool overlaps(AvailabilitySlot o) =>
      weekday == o.weekday && startMin < o.endMin && o.startMin < endMin;

  Map<String, dynamic> toMap() => {'weekday': weekday, 'start': startMin, 'end': endMin};

  factory AvailabilitySlot.fromMap(Map<String, dynamic> m) => AvailabilitySlot(
        weekday: (m['weekday'] ?? 1) as int,
        startMin: (m['start'] ?? 0) as int,
        endMin: (m['end'] ?? 0) as int,
      );
}

const kWeekdayNames = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
];

String fmtMinutes(int m) =>
    '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';

int compareSlots(AvailabilitySlot a, AvailabilitySlot b) =>
    a.weekday != b.weekday ? a.weekday.compareTo(b.weekday) : a.startMin.compareTo(b.startMin);

List<AvailabilitySlot> slotsFor(List<AvailabilitySlot> all, int weekday) =>
    all.where((s) => s.weekday == weekday).toList()..sort(compareSlots);

/// Possible start times (every 30 min) so that a session of [durationMin]
/// fits fully inside one of the [slots].
List<int> startTimesFor(List<AvailabilitySlot> slots, int durationMin) {
  final out = <int>{};
  for (final s in slots) {
    for (var t = s.startMin; t + durationMin <= s.endMin; t += 30) {
      out.add(t);
    }
  }
  return out.toList()..sort();
}
