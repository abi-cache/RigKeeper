import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';

/// Email + password login. On success, does nothing explicitly —
/// AuthGate is listening for the auth state change and will swap to
/// HomeScreen automatically once Supabase confirms the sign-in.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _showResendConfirmation = false;
  bool _isResending = false;

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _showResendConfirmation = false;
    });

    try {
      await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // No navigation needed here — AuthGate handles it.
    } on AuthException catch (e) {
      // Supabase returns a specific message when the account exists
      // but hasn't confirmed its email yet — worth distinguishing
      // from "wrong password" since the fix is completely different
      // (check inbox, not retype credentials).
      final isUnconfirmed = e.message.toLowerCase().contains('confirm');
      setState(() {
        _errorMessage = isUnconfirmed
            ? "Your email isn't confirmed yet. Check your inbox, or resend the confirmation email below."
            : 'Login failed. Check your email and password.';
        _showResendConfirmation = isUnconfirmed;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Something went wrong. Try again in a moment.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resendConfirmation() async {
    setState(() => _isResending = true);
    try {
      await supabase.auth.resend(
        type: OtpType.signup,
        email: _emailController.text.trim(),
      );
      setState(() {
        _errorMessage = 'Confirmation email resent — check your inbox.';
        _showResendConfirmation = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Couldn't resend. Try again in a moment.";
      });
    } finally {
      setState(() => _isResending = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Welcome back',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('Log in to your PCs',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 32),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(_errorMessage!,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.error)),
              ],
              if (_showResendConfirmation) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: _isResending ? null : _resendConfirmation,
                    child: Text(_isResending
                        ? 'Resending...'
                        : 'Resend confirmation email'),
                  ),
                ),
              ],
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ForgotPasswordScreen()),
                    );
                  },
                  child: const Text('Forgot password?'),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _isLoading ? null : _signIn,
                child: _isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Log in'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SignUpScreen()),
                  );
                },
                child: const Text("Don't have an account? Sign up"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}