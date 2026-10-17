import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/availability.dart';
import '../../models/session.dart';
import '../../providers/providers.dart';
import '../../utils/format.dart';

/// Pick a date inside the partner's availability, choose a start time and
/// duration, and send the proposal. The partner confirms or declines it.
class ProposeSessionScreen extends ConsumerStatefulWidget {
  final String chatId, otherId, otherName, otherPhotoUrl;
  const ProposeSessionScreen({
    super.key,
    required this.chatId,
    required this.otherId,
    required this.otherName,
    this.otherPhotoUrl = '',
  });
  @override
  ConsumerState<ProposeSessionScreen> createState() => _ProposeSessionScreenState();
}

class _ProposeSessionScreenState extends ConsumerState<ProposeSessionScreen> {
  final _form = GlobalKey<FormState>();
  final _topic = TextEditingController();
  final _note = TextEditingController();
  DateTime? _date;
  int? _startMin;
  int _duration = 60;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _topic.dispose();
    _note.dispose();
    super.dispose();
  }

  DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  DateTime _firstSelectable(List<AvailabilitySlot> avail) {
    final t = _today;
    if (avail.isEmpty) return t;
    for (var i = 0; i < 14; i++) {
      final c = DateTime(t.year, t.month, t.day + i);
      if (avail.any((s) => s.weekday == c.weekday)) return c;
    }
    return t;
  }

  Future<void> _pickDate(List<AvailabilitySlot> avail) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? _firstSelectable(avail),
      firstDate: _today,
      lastDate: DateTime(_today.year, _today.month, _today.day + 60),
      selectableDayPredicate:
          avail.isEmpty ? null : (d) => avail.any((s) => s.weekday == d.weekday),
    );
    if (picked != null) setState(() { _date = picked; _startMin = null; });
  }

  Future<void> _pickFreeTime() async {
    final t = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 17, minute: 0));
    if (t != null) setState(() => _startMin = t.hour * 60 + t.minute);
  }

  List<int> _options(List<AvailabilitySlot> avail) {
    if (_date == null || avail.isEmpty) return const [];
    final all = startTimesFor(slotsFor(avail, _date!.weekday), _duration);
    final now = DateTime.now();
    if (DateUtils.isSameDay(_date, now)) {
      final nowMin = now.hour * 60 + now.minute;
      return all.where((m) => m > nowMin).toList();
    }
    return all;
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_form.currentState!.validate()) return;
    if (_date == null || _startMin == null) {
      setState(() => _error = 'Pick a date and a start time.');
      return;
    }
    final start = DateTime(_date!.year, _date!.month, _date!.day, _startMin! ~/ 60, _startMin! % 60);
    final end = start.add(Duration(minutes: _duration));
    if (!start.isAfter(DateTime.now())) {
      setState(() => _error = 'Choose a time in the future.');
      return;
    }
    final mine = ref.read(sessionsProvider).valueOrNull ?? const <Session>[];
    if (mine.any((s) => s.status == 'confirmed' && s.overlapsRange(start, end))) {
      setState(() => _error = 'You already have a confirmed session at that time.');
      return;
    }
    final me = ref.read(profileProvider).valueOrNull;
    if (me == null) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      await ref.read(sessionServiceProvider).propose(Session(
            chatId: widget.chatId,
            proposerId: me.uid,
            proposerName: me.name,
            proposerPhotoUrl: me.photoUrl,
            inviteeId: widget.otherId,
            inviteeName: widget.otherName,
            inviteePhotoUrl: widget.otherPhotoUrl,
            topic: _topic.text.trim(),
            note: _note.text.trim(),
            startAt: start,
            durationMin: _duration,
          ));
      if (mounted) Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(content: Text('Session proposed to ${widget.otherName}')));
    } catch (_) {
      if (mounted) setState(() { _saving = false; _error = 'Could not send the proposal. Try again.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final partner = ref.watch(userProfileProvider(widget.otherId));
    return Scaffold(
      appBar: AppBar(title: Text('Session with ${widget.otherName}')),
      body: partner.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load availability.\n$e', textAlign: TextAlign.center)),
        data: (p) => _body(p?.availability ?? const []),
      ),
    );
  }

  Widget _body(List<AvailabilitySlot> avail) {
    final theme = Theme.of(context);
    final options = _options(avail);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _availabilitySummary(avail),
              const SizedBox(height: 18),
              TextFormField(
                controller: _topic,
                decoration: const InputDecoration(labelText: 'What will you practise?', hintText: 'e.g. Flutter state management'),
                validator: (v) => (v == null || v.trim().length < 3) ? 'Enter a topic' : null,
              ),
              const SizedBox(height: 16),
              Text('Duration', style: theme.textTheme.labelLarge),
              const SizedBox(height: 6),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 30, label: Text('30 min')),
                  ButtonSegment(value: 60, label: Text('60 min')),
                  ButtonSegment(value: 90, label: Text('90 min')),
                ],
                selected: {_duration},
                onSelectionChanged: (s) => setState(() {
                  _duration = s.first;
                  if (avail.isNotEmpty && !_options(avail).contains(_startMin)) _startMin = null;
                }),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.calendar_month),
                label: Text(_date == null ? 'Pick a date' : fmtDate(_date!)),
                onPressed: () => _pickDate(avail),
              ),
              const SizedBox(height: 12),
              if (_date != null && avail.isNotEmpty) ...[
                Text('Start time', style: theme.textTheme.labelLarge),
                const SizedBox(height: 6),
                if (options.isEmpty)
                  const Text('No free start times for this duration. Try a shorter session or another day.')
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final m in options)
                        ChoiceChip(
                          label: Text(fmtMinutes(m)),
                          selected: _startMin == m,
                          onSelected: (_) => setState(() => _startMin = m),
                        ),
                    ],
                  ),
              ],
              if (_date != null && avail.isEmpty)
                OutlinedButton.icon(
                  icon: const Icon(Icons.schedule),
                  label: Text(_startMin == null ? 'Pick a start time' : 'Starts ${fmtMinutes(_startMin!)}'),
                  onPressed: _pickFreeTime,
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _note,
                maxLines: 2,
                maxLength: 200,
                decoration: const InputDecoration(labelText: 'Note (optional)', alignLabelWithHint: true),
              ),
              if (_error != null) ...[
                const SizedBox(height: 4),
                Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              ],
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Propose session'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _availabilitySummary(List<AvailabilitySlot> avail) {
    final theme = Theme.of(context);
    if (avail.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text('${widget.otherName} has not set availability yet. You can still propose any date and time.'),
      );
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("${widget.otherName}'s availability", style: theme.textTheme.titleSmall),
          const SizedBox(height: 6),
          for (var d = 1; d <= 7; d++)
            if (slotsFor(avail, d).isNotEmpty)
              Text('${kWeekdayNames[d - 1].substring(0, 3)}: ${slotsFor(avail, d).map((s) => s.label).join(', ')}'),
        ],
      ),
    );
  }
}
