import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';
import '../../utils/format.dart';
import '../../widgets/user_avatar.dart';
import 'chat_screen.dart';

class ChatsScreen extends ConsumerWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(authStateProvider).valueOrNull?.uid ?? '';
    final chats = ref.watch(chatsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: chats.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load chats.\n$e', textAlign: TextAlign.center)),
        data: (list) => list.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No chats yet.\nA chat opens when a swap request is accepted.', textAlign: TextAlign.center),
                ),
              )
            : ListView.separated(
                itemCount: list.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final c = list[i];
                  final name = c.otherName(me);
                  final preview = c.lastMessage.isEmpty
                      ? 'Say hello!'
                      : (c.lastSenderId == me ? 'You: ${c.lastMessage}' : c.lastMessage);
                  return ListTile(
                    leading: UserAvatar(name: name, photoUrl: c.otherPhoto(me)),
                    title: Text(name),
                    subtitle: Text(preview, maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: Text(timeAgo(c.sortTime), style: Theme.of(context).textTheme.bodySmall),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        chatId: c.id,
                        otherName: name,
                        otherPhotoUrl: c.otherPhoto(me),
                      ),
                    )),
                  );
                },
              ),
      ),
    );
  }
}
