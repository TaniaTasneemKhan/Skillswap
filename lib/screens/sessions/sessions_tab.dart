import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/session.dart';
import '../../providers/providers.dart';
import '../../utils/format.dart';
import '../../widgets/user_avatar.dart';
import '../chat/chat_screen.dart';

/// Third tab of the Swaps screen: proposals, upcoming and past sessions.
class SessionsTab extends ConsumerWidget {
  const SessionsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(authStateProvider).valueOrNull?.uid ?? '';
    return ref.watch(sessionsProvider).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Could not load sessions.\n$e', textAlign: TextAlign.center)),
          data: (all) {
            if (all.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No sessions yet.\nOpen a chat and tap the calendar icon to schedule one.', textAlign: TextAlign.center),
                ),
              );
            }
            final now = DateTime.now();
            bool live(Session s) => s.endAt.isAfter(now);
            final needs = all.where((s) => s.status == 'proposed' && s.inviteeId == me && live(s)).toList();
            final upcoming = all.where((s) => s.status == 'confirmed' && live(s)).toList();
            final waiting = all.where((s) => s.status == 'proposed' && s.proposerId == me && live(s)).toList();
            final shown = {...needs, ...upcoming, ...waiting};
            final past = all.where((s) => !shown.contains(s)).toList()
              ..sort((a, b) => b.startAt.compareTo(a.startAt));

            return ListView(
              padding: const EdgeInsets.all(12),
              children: [
                ..._section(context, 'Needs your response', needs),
                ..._section(context, 'Upcoming', upcoming),
                ..._section(context, 'Waiting for reply', waiting),
                ..._section(context, 'Past', past),
              ],
            );
          },
        );
  }

  List<Widget> _section(BuildContext context, String title, List<Session> items) {
    if (items.isEmpty) return const [];
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
        child: Text(title, style: Theme.of(context).textTheme.titleSmall),
      ),
      for (final s in items) _SessionCard(s),
    ];
  }
}

class _SessionCard extends ConsumerWidget {
  final Session s;
  const _SessionCard(this.s);

  Future<bool> _confirm(BuildContext context, String title) async =>
      (await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(title),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes')),
          ],
        ),
      )) ??
      false;

  Future<void> _run(BuildContext context, Future<void> Function() action, String done) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      messenger.showSnackBar(SnackBar(content: Text(done)));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('Action failed. Please try again.')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(authStateProvider).valueOrNull!.uid;
    final svc = ref.read(sessionServiceProvider);
    final theme = Theme.of(context);
    final name = s.partnerName(me);
    final now = DateTime.now();
    final started = !s.startAt.isAfter(now);

    final buttons = <Widget>[];
    if (s.status == 'proposed' && s.inviteeId == me && s.endAt.isAfter(now)) {
      buttons.addAll([
        OutlinedButton(
          onPressed: () => _run(context, () => svc.decline(s, me), 'Session declined'),
          child: const Text('Decline'),
        ),
        FilledButton(
          onPressed: () {
            final mine = ref.read(sessionsProvider).valueOrNull ?? const <Session>[];
            if (mine.any((o) => o.id != s.id && o.status == 'confirmed' && o.overlapsRange(s.startAt, s.endAt))) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('You already have a confirmed session at that time.')));
              return;
            }
            _run(context, () => svc.confirm(s, me), 'Session confirmed');
          },
          child: const Text('Confirm'),
        ),
      ]);
    } else if (s.status == 'proposed' && s.proposerId == me && s.endAt.isAfter(now)) {
      buttons.add(TextButton(
        onPressed: () => _run(context, () => svc.cancel(s, me), 'Proposal cancelled'),
        child: const Text('Cancel proposal'),
      ));
    } else if (s.status == 'confirmed') {
      if (s.endAt.isAfter(now)) {
        buttons.add(TextButton(
          onPressed: () async {
            if (await _confirm(context, 'Cancel this session?') && context.mounted) {
              await _run(context, () => svc.cancel(s, me), 'Session cancelled');
            }
          },
          child: const Text('Cancel'),
        ));
      }
      if (started) {
        buttons.add(FilledButton(
          onPressed: () => _run(context, () => svc.complete(s, me), 'Marked as completed'),
          child: const Text('Mark completed'),
        ));
      }
    }
    if (s.status != 'declined' && s.status != 'cancelled') {
      buttons.insert(
        0,
        IconButton(
          tooltip: 'Open chat',
          icon: const Icon(Icons.chat_bubble_outline),
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ChatScreen(chatId: s.chatId, otherName: name, otherPhotoUrl: s.partnerPhoto(me)),
          )),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                UserAvatar(name: name, photoUrl: s.partnerPhoto(me), radius: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.topic, style: theme.textTheme.titleMedium),
                      Text('with $name', style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                _SessionStatusChip(s.status),
              ],
            ),
            const SizedBox(height: 10),
            Row(children: [
              const Icon(Icons.event, size: 16),
              const SizedBox(width: 6),
              Text('${fmtDate(s.startAt)}  ${fmtRange(s.startAt, s.endAt)}  (${s.durationMin} min)'),
            ]),
            if (s.note.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(s.note, style: theme.textTheme.bodySmall),
            ],
            if (buttons.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                children: buttons,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SessionStatusChip extends StatelessWidget {
  final String status;
  const _SessionStatusChip(this.status);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (label, color) = switch (status) {
      'confirmed' => ('Confirmed', Colors.green.shade100),
      'declined' => ('Declined', scheme.errorContainer),
      'cancelled' => ('Cancelled', scheme.surfaceContainerHighest),
      'completed' => ('Completed', scheme.primaryContainer),
      _ => ('Proposed', scheme.tertiaryContainer),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
      child: Text(label, style: const TextStyle(fontSize: 11)),
    );
  }
}
