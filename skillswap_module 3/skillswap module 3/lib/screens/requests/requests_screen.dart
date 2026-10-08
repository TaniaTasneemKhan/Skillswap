import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/exchange_request.dart';
import '../../providers/providers.dart';
import '../../utils/format.dart';
import '../../widgets/user_avatar.dart';
import '../chat/chat_screen.dart';

class RequestsScreen extends ConsumerWidget {
  const RequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingIncomingCountProvider);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Swap requests'),
          bottom: TabBar(tabs: [
            Tab(
              child: Badge(
                isLabelVisible: pending > 0,
                label: Text('$pending'),
                offset: const Offset(14, -6),
                child: const Text('Received'),
              ),
            ),
            const Tab(text: 'Sent'),
          ]),
        ),
        body: const TabBarView(children: [
          _RequestList(incoming: true),
          _RequestList(incoming: false),
        ]),
      ),
    );
  }
}

class _RequestList extends ConsumerWidget {
  final bool incoming;
  const _RequestList({required this.incoming});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(incoming ? incomingRequestsProvider : sentRequestsProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Could not load requests.\n$e', textAlign: TextAlign.center)),
      data: (list) => list.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  incoming
                      ? 'No requests received yet.'
                      : 'You have not sent any requests.\nFind a partner in Matches or Browse.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: list.length,
              itemBuilder: (_, i) => _RequestCard(list[i], incoming: incoming),
            ),
    );
  }
}

class _RequestCard extends ConsumerWidget {
  final ExchangeRequest r;
  final bool incoming;
  const _RequestCard(this.r, {required this.incoming});

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
    final svc = ref.read(requestServiceProvider);
    final theme = Theme.of(context);
    final name = r.otherName(me);

    // From the viewer's point of view.
    final iTeach = incoming ? r.skillWanted : r.skillOffered;
    final iLearn = incoming ? r.skillOffered : r.skillWanted;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                UserAvatar(name: name, photoUrl: r.otherPhoto(me), radius: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: theme.textTheme.titleMedium),
                      Text(incoming ? 'wants to swap with you' : 'request sent',
                          style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                _StatusChip(r.status),
                const SizedBox(width: 6),
                Text(timeAgo(r.createdAt), style: theme.textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 12),
            _line(context, Icons.school, 'You teach', iTeach),
            const SizedBox(height: 4),
            _line(context, Icons.lightbulb_outline, 'You learn', iLearn),
            if (r.message.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(r.message),
              ),
            ],
            if (r.isPending || r.isAccepted) const SizedBox(height: 10),
            if (r.isPending && incoming)
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _run(context, () => svc.reject(r), 'Request declined'),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _run(context, () => svc.accept(r), 'Accepted - chat is open'),
                    child: const Text('Accept'),
                  ),
                ),
              ]),
            if (r.isPending && !incoming)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _run(context, () => svc.cancel(r), 'Request cancelled'),
                  child: const Text('Cancel request'),
                ),
              ),
            if (r.isAccepted)
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: const Text('Open chat'),
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      chatId: r.chatId,
                      otherName: name,
                      otherPhotoUrl: r.otherPhoto(me),
                    ),
                  )),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _line(BuildContext context, IconData icon, String label, String skill) => Row(
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text('$label: ', style: Theme.of(context).textTheme.bodyMedium),
          Expanded(child: Text(skill, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      );
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip(this.status);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (label, color) = switch (status) {
      'accepted' => ('Accepted', Colors.green.shade100),
      'rejected' => ('Declined', scheme.errorContainer),
      'cancelled' => ('Cancelled', scheme.surfaceContainerHighest),
      _ => ('Pending', scheme.tertiaryContainer),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
      child: Text(label, style: const TextStyle(fontSize: 11)),
    );
  }
}
