import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/exchange_request.dart';
import '../providers/providers.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/requests/send_request_sheet.dart';
import '../services/chat_service.dart';

/// Shows the right action for "me <-> other": request, requested, or open chat.
class RequestButton extends ConsumerWidget {
  final String otherId, otherName, otherPhotoUrl;
  final String initialOffered, initialWanted;
  const RequestButton({
    super.key,
    required this.otherId,
    required this.otherName,
    this.otherPhotoUrl = '',
    this.initialOffered = '',
    this.initialWanted = '',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(authStateProvider).valueOrNull?.uid;
    final all = ref.watch(requestsProvider).valueOrNull ?? const <ExchangeRequest>[];
    if (me == null || me == otherId) return const SizedBox.shrink();

    final between = all.where((r) => r.otherId(me) == otherId);
    if (between.any((r) => r.isAccepted)) {
      return OutlinedButton.icon(
        icon: const Icon(Icons.chat_bubble_outline, size: 18),
        label: const Text('Open chat'),
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatId: ChatService.chatIdFor(me, otherId),
            otherName: otherName,
            otherPhotoUrl: otherPhotoUrl,
          ),
        )),
      );
    }
    final pending = between.where((r) => r.isPending);
    if (pending.any((r) => r.fromId == me)) {
      return const FilledButton.tonal(onPressed: null, child: Text('Request sent'));
    }
    if (pending.isNotEmpty) {
      return const FilledButton.tonal(
          onPressed: null, child: Text('Request received - see Requests tab'));
    }
    return FilledButton.tonalIcon(
      icon: const Icon(Icons.swap_horiz, size: 18),
      label: const Text('Request swap'),
      onPressed: () => showSendRequestSheet(
        context,
        otherId: otherId,
        otherName: otherName,
        otherPhotoUrl: otherPhotoUrl,
        initialOffered: initialOffered,
        initialWanted: initialWanted,
      ),
    );
  }
}
