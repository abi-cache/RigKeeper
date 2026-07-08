import 'package:flutter/material.dart';
import '../../main.dart';

/// Sends a password reset email via Supabase.
///
/// Supabase handles the actual reset flow (generating a secure link,
/// emailing it, verifying it) — this screen just triggers that and
/// shows a confirmation. We don't build our own token/reset logic,
/// since re-implementing secure password reset from scratch is a
/// common source of security bugs; letting Supabase's Auth service
/// handle it is the safer, standard choice.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isSending = false;
  String? _message;
  bool _success = false;

  Future<void> _sendResetEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _message = 'Enter your email first.');
      return;
    }

    setState(() {
      _isSending = true;
      _message = null;
    });

    try {
      await supabase.auth.resetPasswordForEmail(email);
      setState(() {
        _success = true;
        _message =
            'If an account exists for $email, a reset link has been sent. Check your inbox.';
      });
    } catch (e) {
      setState(() {
        _success = false;
        _message = 'Something went wrong. Try again in a moment.';
      });
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset password')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Enter the email on your account and we\'ll send a link to reset your password.',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                enabled: !_success,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_message != null) ...[
                const SizedBox(height: 12),
                Text(
                  _message!,
                  style: TextStyle(
                    color: _success ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              if (!_success)
                ElevatedButton(
                  onPressed: _isSending ? null : _sendResetEmail,
                  child: _isSending
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Send reset link'),
                )
              else
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Back to login'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}