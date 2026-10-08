import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/exchange_request.dart';
import '../../providers/providers.dart';

Future<void> showSendRequestSheet(
  BuildContext context, {
  required String otherId,
  required String otherName,
  String otherPhotoUrl = '',
  String initialOffered = '',
  String initialWanted = '',
}) {
  final messenger = ScaffoldMessenger.of(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: _SendRequestForm(
        otherId: otherId,
        otherName: otherName,
        otherPhotoUrl: otherPhotoUrl,
        initialOffered: initialOffered,
        initialWanted: initialWanted,
        messenger: messenger,
      ),
    ),
  );
}

class _SendRequestForm extends ConsumerStatefulWidget {
  final String otherId, otherName, otherPhotoUrl, initialOffered, initialWanted;
  final ScaffoldMessengerState messenger;
  const _SendRequestForm({
    required this.otherId,
    required this.otherName,
    required this.otherPhotoUrl,
    required this.initialOffered,
    required this.initialWanted,
    required this.messenger,
  });
  @override
  ConsumerState<_SendRequestForm> createState() => _SendRequestFormState();
}

class _SendRequestFormState extends ConsumerState<_SendRequestForm> {
  final _form = GlobalKey<FormState>();
  late final _offered = TextEditingController(text: widget.initialOffered);
  late final _wanted = TextEditingController(text: widget.initialWanted);
  final _message = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _offered.dispose();
    _wanted.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_form.currentState!.validate()) return;
    final me = ref.read(profileProvider).valueOrNull;
    if (me == null) return;
    setState(() => _sending = true);
    try {
      await ref.read(requestServiceProvider).send(ExchangeRequest(
            fromId: me.uid,
            fromName: me.name,
            fromPhotoUrl: me.photoUrl,
            toId: widget.otherId,
            toName: widget.otherName,
            toPhotoUrl: widget.otherPhotoUrl,
            skillOffered: _offered.text.trim(),
            skillWanted: _wanted.text.trim(),
            message: _message.text.trim(),
          ));
      if (mounted) Navigator.of(context).pop();
      widget.messenger.showSnackBar(
          SnackBar(content: Text('Request sent to ${widget.otherName}')));
    } catch (_) {
      if (mounted) {
        setState(() => _sending = false);
        widget.messenger.showSnackBar(
            const SnackBar(content: Text('Could not send request. Try again.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Swap with ${widget.otherName}',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: _offered,
                decoration: const InputDecoration(labelText: 'I will teach'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _wanted,
                decoration: const InputDecoration(labelText: 'I want to learn'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _message,
                maxLines: 3,
                maxLength: 200,
                decoration: const InputDecoration(
                    labelText: 'Message (optional)', alignLabelWithHint: true),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _sending ? null : _send,
                child: _sending
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Send request'),
              ),
            ],
          ),
        ),
      );
}
