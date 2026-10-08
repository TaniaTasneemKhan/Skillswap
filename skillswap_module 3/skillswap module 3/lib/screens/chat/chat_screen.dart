import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/chat.dart';
import '../../providers/providers.dart';
import '../../utils/format.dart';
import '../../widgets/user_avatar.dart';

/// Real-time one-to-one chat backed by chats/{chatId}/messages.
class ChatScreen extends ConsumerStatefulWidget {
  final String chatId, otherName, otherPhotoUrl;
  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherName,
    this.otherPhotoUrl = '',
  });
  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _ctrl = TextEditingController();
  bool _canSend = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    final me = ref.read(authStateProvider).valueOrNull?.uid;
    if (text.isEmpty || me == null) return;
    _ctrl.clear();
    setState(() => _canSend = false);
    try {
      await ref.read(chatServiceProvider).send(widget.chatId, me, text);
    } catch (_) {
      if (!mounted) return;
      _ctrl.text = text; // give the text back so nothing is lost
      setState(() => _canSend = true);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message not sent. Check your connection.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(authStateProvider).valueOrNull?.uid ?? '';
    final messages = ref.watch(messagesProvider(widget.chatId));

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(children: [
          UserAvatar(name: widget.otherName, photoUrl: widget.otherPhotoUrl, radius: 17),
          const SizedBox(width: 10),
          Expanded(child: Text(widget.otherName, overflow: TextOverflow.ellipsis)),
        ]),
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Could not load messages.\n$e', textAlign: TextAlign.center)),
              data: (list) => list.isEmpty
                  ? Center(child: Text('Say hello to ${widget.otherName}!'))
                  : ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.all(12),
                      itemCount: list.length,
                      itemBuilder: (_, i) => _Bubble(list[i], mine: list[i].senderId == me),
                    ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: 1000,
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: (v) => setState(() => _canSend = v.trim().isNotEmpty),
                      decoration: const InputDecoration(
                        hintText: 'Type a message',
                        counterText: '',
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton.filled(
                    icon: const Icon(Icons.send),
                    onPressed: _canSend ? _send : null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage m;
  final bool mine;
  const _Bubble(this.m, {required this.mine});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: mine ? scheme.primary : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(mine ? 16 : 4),
            bottomRight: Radius.circular(mine ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(m.text, style: TextStyle(color: mine ? scheme.onPrimary : scheme.onSurface)),
            const SizedBox(height: 2),
            Text(
              clockTime(m.createdAt),
              style: TextStyle(
                fontSize: 10,
                color: (mine ? scheme.onPrimary : scheme.onSurface).withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
