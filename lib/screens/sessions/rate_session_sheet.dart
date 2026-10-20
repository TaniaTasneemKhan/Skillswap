import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/session.dart';
import '../../providers/providers.dart';
import '../../services/review_service.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/star_rating.dart';

Future<void> showRateSessionSheet(BuildContext context, Session session) {
  final messenger = ScaffoldMessenger.of(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: _RateForm(session: session, messenger: messenger),
    ),
  );
}

class _RateForm extends ConsumerStatefulWidget {
  final Session session;
  final ScaffoldMessengerState messenger;
  const _RateForm({required this.session, required this.messenger});
  @override
  ConsumerState<_RateForm> createState() => _RateFormState();
}

class _RateFormState extends ConsumerState<_RateForm> {
  final _comment = TextEditingController();
  int _rating = 0;
  bool _saving = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final me = ref.read(profileProvider).valueOrNull;
    if (me == null || _rating == 0) return;
    setState(() => _saving = true);
    try {
      await ref.read(reviewServiceProvider).submit(
            session: widget.session,
            reviewerId: me.uid,
            reviewerName: me.name,
            reviewerPhotoUrl: me.photoUrl,
            rating: _rating,
            comment: _comment.text.trim(),
          );
      if (mounted) Navigator.of(context).pop();
      widget.messenger.showSnackBar(const SnackBar(content: Text('Thanks for your review!')));
    } on AlreadyReviewedException {
      if (mounted) Navigator.of(context).pop();
      widget.messenger.showSnackBar(const SnackBar(content: Text('You already reviewed this session.')));
    } catch (_) {
      if (mounted) setState(() => _saving = false);
      widget.messenger.showSnackBar(
          const SnackBar(content: Text('Could not save your review. Please try again.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(authStateProvider).valueOrNull?.uid ?? '';
    final name = widget.session.partnerName(me);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('How was your session with $name?',
              textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(widget.session.topic, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          StarPicker(value: _rating, onChanged: (v) => setState(() => _rating = v)),
          const SizedBox(height: 8),
          TextField(
            controller: _comment,
            maxLines: 3,
            maxLength: 500,
            decoration: const InputDecoration(
              labelText: 'Write a review (optional)',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          GradientButton(
            onPressed: (_rating == 0 || _saving) ? null : _submit,
            loading: _saving,
            child: const Text('Submit review'),
          ),
        ],
      ),
    );
  }
}
