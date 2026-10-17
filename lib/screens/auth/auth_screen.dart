import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';
import '../../services/auth_service.dart';

/// Single screen that toggles between Login and Sign up.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});
  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isLogin = true;
  bool _busy = false;
  bool _hidePw = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _busy = true; _error = null; });
    final auth = ref.read(authServiceProvider);
    try {
      _isLogin
          ? await auth.signIn(_email.text, _password.text)
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
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.swap_horiz_rounded, size: 64, color: theme.colorScheme.primary),
                    const SizedBox(height: 8),
                    Text('SkillSwap',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                    Text(_isLogin ? 'Welcome back' : 'Create your account',
                        textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                      validator: (v) {
                        final s = v?.trim() ?? '';
                        if (s.isEmpty) return 'Email is required';
                        if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s)) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _password,
                      obscureText: _hidePw,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_hidePw ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _hidePw = !_hidePw),
                        ),
                      ),
                      validator: (v) => (v == null || v.length < 6) ? 'At least 6 characters' : null,
                    ),
                    if (!_isLogin) ...[
                      const SizedBox(height: 14),
                      TextFormField(
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Confirm password', prefixIcon: Icon(Icons.lock_outline)),
                        validator: (v) => v != _password.text ? 'Passwords do not match' : null,
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(_isLogin ? 'Log in' : 'Sign up'),
                    ),
                    if (_isLogin)
                      TextButton(onPressed: _forgot, child: const Text('Forgot password?')),
                    TextButton(
                      onPressed: () => setState(() { _isLogin = !_isLogin; _error = null; }),
                      child: Text(_isLogin ? "New here? Create an account" : 'Already have an account? Log in'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
