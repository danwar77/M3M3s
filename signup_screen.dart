import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Placeholder LoginScreen for navigation from SignUpScreen
// In a real app, this would be in 'login_screen.dart' and imported.
class LoginScreen extends StatelessWidget { // Simplified version for this file's context
  const LoginScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: const Center(child: Text('Login Screen Placeholder (Navigated from Sign Up)')),
    );
  }
}

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _performSignUp() async {
    if (_isLoading) return;

    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      if (mounted) {
        setState(() => _isLoading = true);
      }
      scaffoldMessenger.removeCurrentSnackBar();

      try {
        final AuthResponse response = await Supabase.instance.client.auth.signUp(
          email: email,
          password: password,
        );

        if (mounted) {
          if (response.user != null) {
            bool emailConfirmationRequired = response.session == null && (response.user?.emailConfirmedAt == null);

            if (emailConfirmationRequired) {
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: const Text('Sign-up successful! Please check your email to confirm your account.'),
                  backgroundColor: Colors.orangeAccent.shade700,
                  duration: const Duration(seconds: 6),
                ),
              );
              // Navigate to login after showing confirmation message
              Future.delayed(const Duration(seconds: 3), () { // Short delay for user to read
                if(mounted) _navigateToLogin();
              });
            } else {
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: const Text('Sign-up successful! You are now logged in.'),
                  backgroundColor: Colors.green.shade700,
                ),
              );
              // AuthState listener in main_app_structure.dart should handle navigation.
            }
          } else {
             scaffoldMessenger.showSnackBar(
              SnackBar(
                content: const Text('Sign-up completed, but user data is currently unavailable. Please try logging in.'),
                backgroundColor: Colors.orangeAccent.shade700,
              ),
            );
          }
        }

      } on AuthException catch (e) {
        if (mounted) {
          String errorMessage = 'Sign-up failed. Please try again.';
           if (e.message.toLowerCase().contains('user already registered') ||
               e.message.toLowerCase().contains('email address already registered')) {
            errorMessage = 'This email is already registered. Please try logging in.';
          } else if (e.message.toLowerCase().contains('password should be at least 6 characters')) {
            errorMessage = 'Password is too short. It must be at least 6 characters.';
          } else if (e.message.toLowerCase().contains('check your inbox for confirmation instructions')) {
             errorMessage = 'Sign-up successful! Please check your email to confirm your account.';
             scaffoldMessenger.showSnackBar(
                SnackBar(content: Text(errorMessage), backgroundColor: Colors.orangeAccent.shade700, duration: const Duration(seconds: 6)),
             );
             if (mounted) setState(() => _isLoading = false);
             // Navigate to login after showing confirmation message
             Future.delayed(const Duration(seconds: 3), () {
                if(mounted) _navigateToLogin();
             });
             return;
          }
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('An unexpected error occurred: ${e.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _navigateToLogin() {
    if (_isLoading) return; // Don't navigate if an operation is in progress

    if (Navigator.canPop(context)) {
      Navigator.pop(context); // Assumes SignUpScreen was pushed onto LoginScreen
    } else {
      // Fallback if it cannot be popped (e.g., direct navigation for testing, or different routing)
      // TODO: Replace with actual named route if using a router like GoRouter
      // Navigator.pushReplacementNamed(context, '/login');
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Navigating to Login Screen (Fallback).'), backgroundColor: Theme.of(context).colorScheme.secondary),
      );
      // This is a placeholder, actual navigation might differ based on app's routing setup
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));

    }
    print('Navigate to Login Screen');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: screenSize.width > 600 ? 450 : double.infinity),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Icon(
                    Icons.person_add_alt_1_outlined,
                    size: 72,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Join MemeMarvel!',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create an account to start the fun.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 40),

                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      hintText: 'you@example.com',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value.trim())) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Choose a strong password (min. 6 characters)',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      suffixIcon: IconButton(
                        icon: Icon(_passwordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                        onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
                      ),
                    ),
                    obscureText: !_passwordVisible,
                    textInputAction: TextInputAction.next,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters long';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _confirmPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      hintText: 'Re-enter your password',
                      prefixIcon: const Icon(Icons.lock_person_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                       suffixIcon: IconButton(
                        icon: Icon(_confirmPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                        onPressed: () => setState(() => _confirmPasswordVisible = !_confirmPasswordVisible),
                      ),
                    ),
                    obscureText: !_confirmPasswordVisible,
                    textInputAction: TextInputAction.done,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                     onFieldSubmitted: (_) => _performSignUp(),
                  ),
                  const SizedBox(height: 32),

                  _isLoading
                      ? const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()))
                      : ElevatedButton.icon(
                          icon: const Icon(Icons.person_add_rounded),
                          label: const Text('CREATE ACCOUNT'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            textStyle: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _performSignUp,
                        ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Already have an account?", style: theme.textTheme.bodyMedium),
                      TextButton(
                        onPressed: _isLoading ? null : _navigateToLogin,
                        child: Text('Login Here', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.secondary)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```
