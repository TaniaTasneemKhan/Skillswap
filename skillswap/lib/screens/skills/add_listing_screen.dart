import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/skill_listing.dart';
import '../../providers/providers.dart';

class AddListingScreen extends ConsumerStatefulWidget {
  const AddListingScreen({super.key});
  @override
  ConsumerState<AddListingScreen> createState() => _AddListingScreenState();
}

class _AddListingScreenState extends ConsumerState<AddListingScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _desc = TextEditingController();
  String _type = 'offer';
  String _category = kCategories.first;
  String _level = kLevels.first;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final me = ref.read(profileProvider).valueOrNull;
    if (me == null) return;
    setState(() => _saving = true);
    try {
      await ref.read(listingServiceProvider).add(SkillListing(
            ownerId: me.uid,
            ownerName: me.name,
            ownerPhotoUrl: me.photoUrl,
            title: _title.text.trim(),
            category: _category,
            level: _level,
            type: _type,
            description: _desc.text.trim(),
          ));
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not save listing. Try again.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('New listing')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'offer', label: Text('I can teach'), icon: Icon(Icons.school)),
                      ButtonSegment(value: 'want', label: Text('I want to learn'), icon: Icon(Icons.lightbulb_outline)),
                    ],
                    selected: {_type},
                    onSelectionChanged: (s) => setState(() => _type = s.first),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _title,
                    decoration: const InputDecoration(labelText: 'Skill title', hintText: 'e.g. Beginner guitar lessons'),
                    validator: (v) => (v == null || v.trim().length < 3) ? 'Enter a skill title' : null,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: _category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: [for (final c in kCategories) DropdownMenuItem(value: c, child: Text(c))],
                    onChanged: (v) => setState(() => _category = v!),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: _level,
                    decoration: const InputDecoration(labelText: 'Level'),
                    items: [for (final l in kLevels) DropdownMenuItem(value: l, child: Text(l))],
                    onChanged: (v) => setState(() => _level = v!),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _desc,
                    maxLines: 4,
                    maxLength: 300,
                    decoration: const InputDecoration(labelText: 'Description', alignLabelWithHint: true),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Post listing'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
