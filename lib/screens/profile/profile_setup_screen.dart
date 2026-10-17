import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/user_profile.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/banner_header.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/skill_chip_input.dart';
import '../../widgets/user_avatar.dart';

/// First-time profile setup, also reused for "Edit profile" (isEditing: true).
class ProfileSetupScreen extends ConsumerStatefulWidget {
  final bool isEditing;
  const ProfileSetupScreen({super.key, this.isEditing = false});
  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _bio;
  List<String> _offered = [];
  List<String> _wanted = [];
  String _photoUrl = '';
  Uint8List? _newPhoto;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final existing = ref.read(profileProvider).valueOrNull;
    _name = TextEditingController(text: existing?.name ?? '');
    _bio = TextEditingController(text: existing?.bio ?? '');
    _offered = [...?existing?.skillsOffered];
    _wanted = [...?existing?.skillsWanted];
    _photoUrl = existing?.photoUrl ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final x = await ImagePicker()
        .pickImage(source: ImageSource.gallery, maxWidth: 800, imageQuality: 80);
    if (x == null) return;
    final bytes = await x.readAsBytes();
    if (mounted) setState(() => _newPhoto = bytes);
  }

  Future<void> _save() async {
    setState(() => _error = null);
    if (!_form.currentState!.validate()) return;
    if (_offered.isEmpty || _wanted.isEmpty) {
      setState(() => _error = 'Add at least one skill you offer and one you want to learn.');
      return;
    }
    setState(() => _saving = true);
    try {
      final user = ref.read(authStateProvider).valueOrNull!;
      final users = ref.read(userServiceProvider);
      var url = _photoUrl;
      if (_newPhoto != null) url = await users.uploadPhoto(user.uid, _newPhoto!);
      await users.save(UserProfile(
        uid: user.uid,
        name: _name.text.trim(),
        email: user.email ?? '',
        bio: _bio.text.trim(),
        photoUrl: url,
        skillsOffered: _offered,
        skillsWanted: _wanted,
        profileComplete: true,
      ));
      if (mounted && widget.isEditing) Navigator.of(context).pop();
      // On first setup, AuthGate swaps to HomeShell automatically.
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not save profile. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t, style: const TextStyle(fontWeight: FontWeight.w600, color: Brand.ink)),
      );

  @override
  Widget build(BuildContext context) {
    final avatar = GestureDetector(
      onTap: _pickPhoto,
      child: Stack(
        children: [
          _newPhoto != null
              ? CircleAvatar(radius: 52, backgroundImage: MemoryImage(_newPhoto!))
              : UserAvatar(name: _name.text, photoUrl: _photoUrl, radius: 52),
          const Positioned(
            right: 0,
            bottom: 0,
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Brand.primary,
              child: Icon(Icons.camera_alt, size: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            BannerHeader(
              avatar: avatar,
              child: Row(
                children: [
                  if (widget.isEditing)
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isEditing ? 'Edit profile' : 'Set up your profile',
                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        const Text('Tap the photo to change it',
                            style: TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                  if (!widget.isEditing)
                    TextButton(
                      onPressed: () => ref.read(authServiceProvider).signOut(),
                      child: const Text('Log out', style: TextStyle(color: Colors.white)),
                    ),
                ],
              ),
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  child: Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _label('Full name'),
                        TextFormField(
                          controller: _name,
                          textCapitalization: TextCapitalization.words,
                          onChanged: (_) => setState(() {}),
                          decoration: fieldDecoration(hint: 'e.g. Tania Khan'),
                          validator: (v) => (v == null || v.trim().length < 2) ? 'Enter your name' : null,
                        ),
                        const SizedBox(height: 16),
                        _label('Short bio'),
                        TextFormField(
                          controller: _bio,
                          maxLines: 3,
                          maxLength: 200,
                          decoration: fieldDecoration(hint: 'Tell people a little about you', alignLabelWithHint: true),
                        ),
                        const SizedBox(height: 8),
                        SkillChipInput(
                          label: 'Skills I can teach',
                          hint: 'e.g. Flutter, Guitar, Spanish',
                          values: _offered,
                          onChanged: (v) => setState(() => _offered = v),
                        ),
                        const SizedBox(height: 18),
                        SkillChipInput(
                          label: 'Skills I want to learn',
                          hint: 'e.g. Photoshop, Public speaking',
                          values: _wanted,
                          onChanged: (v) => setState(() => _wanted = v),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                        ],
                        const SizedBox(height: 24),
                        GradientButton(
                          onPressed: _saving ? null : _save,
                          loading: _saving,
                          child: Text(widget.isEditing ? 'Save changes' : 'Finish setup'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
