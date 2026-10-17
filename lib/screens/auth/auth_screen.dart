import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/brand_logo.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/skill_tag.dart';

/// Login / Register. Wide screens get a split card (tagline + illustration
/// on the left, form on the right); phones get a gradient header over the form.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});
  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _isLogin = true;
  bool _busy = false;
  bool _hidePw = true;
  bool _remember = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _setMode(bool login) => setState(() {
        _isLogin = login;
        _error = null;
      });

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _busy = true; _error = null; });
    final auth = ref.read(authServiceProvider);
    try {
      _isLogin
          ? await auth.signIn(_email.text, _password.text, remember: _remember)
          : await auth.signUp(_email.text, _password.text);
      // AuthGate reacts to the auth state change; nothing else to do.
    } catch (e) {
      if (mounted) setState(() => _error = AuthService.friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _forgot() async {
    final email = _email.text.trim();
    if (!email.contains('@')) {
      setState(() => _error = 'Enter your email above first.');
      return;
    }
    try {
      await ref.read(authServiceProvider).sendPasswordReset(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password reset email sent.')));
      }
    } catch (e) {
      if (mounted) setState(() => _error = AuthService.friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 900;
    return Scaffold(
      body: wide
          ? Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFF1ECFF), Color(0xFFE4EEFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(child: Center(child: _wideCard())),
            )
          : _narrow(),
    );
  }

  // ---- wide: split card ----
  Widget _wideCard() => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1040, maxHeight: 640),
        child: Container(
          margin: const EdgeInsets.all(24),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Brand.ink, width: 1.5),
            boxShadow: [
              BoxShadow(color: Brand.primary.withOpacity(0.25), blurRadius: 40, offset: const Offset(0, 16)),
            ],
          ),
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Row(
                  children: [
                    BrandLogo(),
                    Spacer(),
                    Icon(Icons.headset_mic_outlined, size: 20, color: Brand.ink),
                  ],
                ),
              ),
              const Divider(height: 1, color: Brand.ink),
              Expanded(
                child: Row(
                  children: [
                    const Expanded(child: _HeroPanel()),
                    const VerticalDivider(width: 1, color: Brand.ink),
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 24),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 400),
                            child: _formContent(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  // ---- narrow: gradient header + form ----
  Widget _narrow() => SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 32, 24, 32),
              decoration: const BoxDecoration(
                gradient: Brand.gradient,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BrandLogo(light: true),
                  SizedBox(height: 24),
                  Text(
                    'Swap Skills,\nLearn More.',
                    style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800, height: 1.15),
                  ),
                  SizedBox(height: 8),
                  Text('Teach what you know. Learn what you want.',
                      style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Padding(padding: const EdgeInsets.all(24), child: _formContent()),
              ),
            ),
          ],
        ),
      );

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t, style: const TextStyle(fontWeight: FontWeight.w600, color: Brand.ink)),
      );

  Widget _formContent() => Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ModeToggle(isLogin: _isLogin, onChanged: _setMode),
            const SizedBox(height: 20),
            Text(
              _isLogin ? "Let's log in to your account." : 'Create your free account.',
              style: const TextStyle(fontSize: 20, color: Brand.ink),
            ),
            const SizedBox(height: 20),
            _label('Email'),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: fieldDecoration(hint: 'example@gmail.com'),
              validator: (v) {
                final s = v?.trim() ?? '';
                if (s.isEmpty) return 'Email is required';
                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s)) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 14),
            _label('Password'),
            TextFormField(
              controller: _password,
              obscureText: _hidePw,
              decoration: fieldDecoration(
                hint: 'Enter your password',
                suffix: IconButton(
                  icon: Icon(_hidePw ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                  onPressed: () => setState(() => _hidePw = !_hidePw),
                ),
              ),
              validator: (v) => (v == null || v.length < 6) ? 'At least 6 characters' : null,
            ),
            if (!_isLogin) ...[
              const SizedBox(height: 14),
              _label('Confirm password'),
              TextFormField(
                controller: _confirm,
                obscureText: true,
                decoration: fieldDecoration(hint: 'Re-enter your password'),
                validator: (v) => v != _password.text ? 'Passwords do not match' : null,
              ),
            ],
            if (_isLogin)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    if (kIsWeb) ...[
                      Checkbox(
                        value: _remember,
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onChanged: (v) => setState(() => _remember = v ?? true),
                      ),
                      const Text('Remember me'),
                    ],
                    const Spacer(),
                    TextButton(onPressed: _forgot, child: const Text('Forgot password?')),
                  ],
                ),
              ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 16),
            GradientButton(
              onPressed: _busy ? null : _submit,
              loading: _busy,
              child: Text(_isLogin ? 'Log in' : 'Create account'),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_isLogin ? "Don't have an account? " : 'Already have an account? '),
                InkWell(
                  onTap: () => _setMode(!_isLogin),
                  child: Text(
                    _isLogin ? 'Register' : 'Log in',
                    style: const TextStyle(fontWeight: FontWeight.w700, color: Brand.primary),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}

/// Pill-style Login | Register switch.
class _ModeToggle extends StatelessWidget {
  final bool isLogin;
  final ValueChanged<bool> onChanged;
  const _ModeToggle({required this.isLogin, required this.onChanged});

  Widget _seg(String label, bool selected, VoidCallback onTap) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? Brand.ink : Colors.transparent,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Brand.ink,
              ),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Brand.ink, width: 1.2),
        ),
        child: Row(
          children: [
            _seg('Login', isLogin, () => onChanged(true)),
            _seg('Register', !isLogin, () => onChanged(false)),
          ],
        ),
      );
}

/// Left half of the wide layout: tagline and a mock "swap card" illustration.
class _HeroPanel extends StatelessWidget {
  const _HeroPanel();

  @override
  Widget build(BuildContext context) => Container(
        color: Brand.lavender,
        padding: const EdgeInsets.fromLTRB(40, 36, 40, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Swap Skills, Learn More\nWith SkillSwap.',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, height: 1.15, color: Brand.ink),
            ),
            const SizedBox(height: 10),
            Text('Teach what you know, learn what you want. No money involved.',
                style: TextStyle(color: Brand.ink.withOpacity(0.7))),
            const Expanded(child: Center(child: _Illustration())),
          ],
        ),
      );
}

class _Illustration extends StatelessWidget {
  const _Illustration();

  Widget _chip(String text, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Text(text, style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 12)),
      );

  @override
  Widget build(BuildContext context) => FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: 380,
          height: 320,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 176,
                height: 290,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Brand.ink, width: 3),
                  boxShadow: [BoxShadow(color: Brand.primary.withOpacity(0.25), blurRadius: 24, offset: const Offset(0, 10))],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 6),
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(color: Brand.lavender, shape: BoxShape.circle),
                      child: const Icon(Icons.person, size: 38, color: Brand.primary),
                    ),
                    const SizedBox(height: 8),
                    const Text('Sarah Chen', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.star, size: 14, color: Colors.amber),
                        SizedBox(width: 2),
                        Text('4.9', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Align(alignment: Alignment.centerLeft, child: Text('Can teach', style: TextStyle(fontSize: 10, color: Colors.grey))),
                    const SizedBox(height: 4),
                    const Align(alignment: Alignment.centerLeft, child: SkillTag('Python', compact: true)),
                    const SizedBox(height: 8),
                    const Align(alignment: Alignment.centerLeft, child: Text('Looking to learn', style: TextStyle(fontSize: 10, color: Colors.grey))),
                    const SizedBox(height: 4),
                    const Align(alignment: Alignment.centerLeft, child: SkillTag('Piano', learn: true, compact: true)),
                    const Spacer(),
                    Container(
                      height: 32,
                      width: double.infinity,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(gradient: Brand.gradient, borderRadius: BorderRadius.circular(10)),
                      child: const Text('Request Swap',
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
              Positioned(left: 0, top: 40, child: _chip('Web Development', const Color(0xFFF0E6FF), const Color(0xFF7A3FD1))),
              Positioned(right: 0, top: 90, child: _chip('Guitar', const Color(0xFFDDF7E8), const Color(0xFF1E7A4A))),
              Positioned(left: 8, bottom: 50, child: _chip('Graphic Design', const Color(0xFFE0ECFF), const Color(0xFF2B5FCB))),
              Positioned(
                right: 24,
                bottom: 20,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(gradient: Brand.gradient, shape: BoxShape.circle),
                  child: const Icon(Icons.swap_horiz, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
}
