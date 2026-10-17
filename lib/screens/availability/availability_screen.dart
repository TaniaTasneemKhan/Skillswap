import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/availability.dart';
import '../../providers/providers.dart';

/// Weekly availability editor: add time windows per day, then save.
class AvailabilityScreen extends ConsumerStatefulWidget {
  const AvailabilityScreen({super.key});
  @override
  ConsumerState<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends ConsumerState<AvailabilityScreen> {
  late List<AvailabilitySlot> _slots;
  bool _dirty = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _slots = [...?ref.read(profileProvider).valueOrNull?.availability];
  }

  void _msg(String t) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  Future<void> _add(int weekday) async {
    final start = await showTimePicker(
        context: context, helpText: 'From', initialTime: const TimeOfDay(hour: 9, minute: 0));
    if (start == null || !mounted) return;
    final end = await showTimePicker(
        context: context,
        helpText: 'Until',
        initialTime: TimeOfDay(hour: (start.hour + 2) % 24, minute: start.minute));
    if (end == null || !mounted) return;

    final s = start.hour * 60 + start.minute;
    final e = end.hour * 60 + end.minute;
    if (e - s < 30) {
      _msg('The end time must be at least 30 minutes after the start.');
      return;
    }
    final slot = AvailabilitySlot(weekday: weekday, startMin: s, endMin: e);
    if (_slots.any((x) => x.overlaps(slot))) {
      _msg('That overlaps an existing slot on the same day.');
      return;
    }
    setState(() {
      _slots = [..._slots, slot]..sort(compareSlots);
      _dirty = true;
    });
  }

  Future<void> _save() async {
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) return;
    setState(() => _saving = true);
    try {
      await ref.read(userServiceProvider).saveAvailability(uid, _slots);
      if (!mounted) return;
      setState(() { _dirty = false; _saving = false; });
      _msg('Availability saved');
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _msg('Could not save. Check your connection and try again.');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('My availability')),
        body: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                'Add the times you are free each week. Partners can only book sessions inside these windows. Times are in your local time.',
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  for (var day = 1; day <= 7; day++) _dayCard(day),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: (_dirty && !_saving) ? _save : null,
                    child: _saving
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Save availability'),
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _dayCard(int day) {
    final slots = slotsFor(_slots, day);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(kWeekdayNames[day - 1], style: Theme.of(context).textTheme.titleMedium)),
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                  onPressed: () => _add(day),
                ),
              ],
            ),
            if (slots.isEmpty)
              Text('Not available', style: Theme.of(context).textTheme.bodySmall)
            else
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final s in slots)
                    InputChip(
                      label: Text(s.label),
                      onDeleted: () => setState(() {
                        _slots = _slots.where((x) => x != s).toList();
                        _dirty = true;
                      }),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
