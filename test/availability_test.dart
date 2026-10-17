import 'package:flutter_test/flutter_test.dart';
import 'package:skillswap/models/availability.dart';
import 'package:skillswap/models/session.dart';

void main() {
  const mon = AvailabilitySlot(weekday: 1, startMin: 9 * 60, endMin: 11 * 60);

  test('start times fit the whole session inside the slot', () {
    expect(startTimesFor([mon], 60), [540, 570, 600]); // 09:00, 09:30, 10:00
    expect(startTimesFor([mon], 90), [540, 570]);
    expect(startTimesFor([mon], 180), isEmpty);
  });

  test('slots overlap only on the same weekday', () {
    const a = AvailabilitySlot(weekday: 1, startMin: 600, endMin: 720);
    const b = AvailabilitySlot(weekday: 2, startMin: 600, endMin: 720);
    expect(mon.overlaps(a), true);
    expect(mon.overlaps(b), false);
  });

  test('slot map round-trip and label', () {
    final s = AvailabilitySlot.fromMap(mon.toMap());
    expect(s.label, '09:00–11:00');
    expect(s.weekday, 1);
  });

  test('session overlap detection', () {
    final s = Session(
      chatId: 'c', proposerId: 'a', proposerName: 'A', inviteeId: 'b', inviteeName: 'B',
      topic: 't', startAt: DateTime(2026, 10, 24, 16), durationMin: 60,
    );
    expect(s.overlapsRange(DateTime(2026, 10, 24, 16, 30), DateTime(2026, 10, 24, 17, 30)), true);
    expect(s.overlapsRange(DateTime(2026, 10, 24, 17), DateTime(2026, 10, 24, 18)), false);
    expect(s.partnerName('a'), 'B');
  });
}
