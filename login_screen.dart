import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Placeholder SignUpScreen for navigation from LoginScreen
// In a real app, this would be in 'signup_screen.dart' and imported.
class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: const Center(child: Text('Sign Up Screen Placeholder (Navigated from Login)')),
    );
  }
}


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _passwordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _performLogin() async {
    if (_isLoading) return;

    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      if (mounted) {
        setState(() => _isLoading = true);
      }
      scaffoldMessenger.removeCurrentSnackBar(); // Clear previous snackbars

      try {
        final AuthResponse response = await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: password,
        );

        if (mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: const Text('Login successful! Welcome back.'),
              backgroundColor: Colors.green.shade700,
            ),
          );
          // AuthState listener in main_app_structure.dart should handle navigation.
        }

      } on AuthException catch (e) {
        if (mounted) {
          String errorMessage = 'Login failed. Please try again.';
          if (e.message.toLowerCase().contains('invalid login credentials')) {
            errorMessage = 'Invalid email or password. Please check your credentials.';
          } else if (e.message.toLowerCase().contains('email not confirmed')) {
            errorMessage = 'Please confirm your email address before logging in.';
            // TODO: Optionally add a "Resend confirmation email" button/logic here
          } else {
            errorMessage = e.message;
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

  void _navigateToSignUp() {
    if (_isLoading) return;
    // Navigate to the actual SignUpScreen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SignUpScreen()), // Using placeholder defined above
    );
  }

  void _forgotPassword() {
    if (_isLoading) return;
    // TODO: Implement navigation or dialog for password recovery
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Forgot Password functionality (placeholder)'), backgroundColor: Colors.blueGrey),
    );
    print('Forgot Password tapped');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Login to MemeMarvel'),
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
                    Icons.auto_awesome_mosaic,
                    size: 72,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Welcome Back!',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to continue your meme journey.',
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
                      hintText: 'Enter your password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _passwordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _passwordVisible = !_passwordVisible;
                          });
                        },
                      ),
                    ),
                    obscureText: !_passwordVisible,
                    textInputAction: TextInputAction.done,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters long';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _performLogin(),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _isLoading ? null : _forgotPassword,
                      child: Text('Forgot Password?', style: TextStyle(color: theme.colorScheme.secondary)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  _isLoading
                      ? const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()))
                      : ElevatedButton.icon(
                          icon: const Icon(Icons.login_rounded),
                          label: const Text('LOGIN'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            textStyle: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _performLogin,
                        ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Don't have an account?", style: theme.textTheme.bodyMedium),
                      TextButton(
                        onPressed: _isLoading ? null : _navigateToSignUp,
                        child: Text('Sign Up Now', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.secondary)),
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
