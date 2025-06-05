import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Added import

// Placeholder LoginScreen for navigation from SignUpScreen
// In a real app, this would be in 'login_screen.dart' and imported.
class LoginScreen extends StatelessWidget { // Simplified version for this file's context
  const LoginScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!; // Added localization instance
    return Scaffold(
      appBar: AppBar(title: Text(loc.loginScreenTitle)), // Localized
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
    final loc = AppLocalizations.of(context)!; // Added localization instance

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
                  content: Text(loc.signUpSuccessfulEmailConfirmationSnackbar),
                  backgroundColor: Colors.orangeAccent.shade700, 
                  duration: const Duration(seconds: 6), 
                ),
              );
              Future.delayed(const Duration(seconds: 3), () { 
                if(mounted) _navigateToLogin();
              });
            } else {
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text(loc.signUpSuccessfulSnackbar),
                  backgroundColor: Colors.green.shade700,
                ),
              );
            }
          } else {
             scaffoldMessenger.showSnackBar(
              SnackBar(
                // Assuming a key like "signUpCompletedUserUnavailableSnackbar"
                content: Text(loc.signUpFailedSnackbar + " (User data unavailable)"), // Placeholder
                backgroundColor: Colors.orangeAccent.shade700,
              ),
            );
          }
        }

      } on AuthException catch (e) {
        if (mounted) {
          String errorMessage = loc.signUpFailedSnackbar;
           if (e.message.toLowerCase().contains('user already registered') || 
               e.message.toLowerCase().contains('email address already registered')) { 
            errorMessage = loc.signUpFailedUserExistsSnackbar;
          } else if (e.message.toLowerCase().contains('password should be at least 6 characters')) {
            errorMessage = loc.signUpFailedWeakPasswordSnackbar;
          } else if (e.message.toLowerCase().contains('check your inbox for confirmation instructions')) { 
             errorMessage = loc.signUpSuccessfulEmailConfirmationSnackbar;
             scaffoldMessenger.showSnackBar(
                SnackBar(content: Text(errorMessage), backgroundColor: Colors.orangeAccent.shade700, duration: const Duration(seconds: 6)),
             );
             if (mounted) setState(() => _isLoading = false);
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
    if (_isLoading) return; 

    if (Navigator.canPop(context)) {
      Navigator.pop(context); 
    } else {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Navigating to Login Screen (Fallback).'), backgroundColor: Theme.of(context).colorScheme.secondary),
      );
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
    }
    print('Navigate to Login Screen');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final loc = AppLocalizations.of(context)!; // Added localization instance

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.signUpScreenTitle),
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
                    loc.signUpScreenTitle, // Re-using for main title text
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    loc.appTitle, // Using appTitle or create specific key like "signUpTagline"
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 40),

                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: loc.emailLabel,
                      hintText: loc.emailHint,
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (value) {
                      final trimmedValue = value?.trim();
                      if (trimmedValue == null || trimmedValue.isEmpty) {
                        return loc.appTitle; // Placeholder: loc.validatorRequiredEmail
                      }
                      if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(trimmedValue)) {
                        return loc.appTitle; // Placeholder: loc.validatorInvalidEmail
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: loc.passwordLabel,
                      hintText: loc.passwordHintSignUp,
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
                        return loc.appTitle; // Placeholder: loc.validatorRequiredPassword
                      }
                      if (value.length < 6) {
                        return loc.signUpFailedWeakPasswordSnackbar; // Using existing key
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _confirmPasswordController,
                    decoration: InputDecoration(
                      labelText: loc.confirmPasswordLabel,
                      hintText: loc.confirmPasswordHint,
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
                        return loc.appTitle; // Placeholder: loc.validatorRequiredConfirmPassword
                      }
                      if (value != _passwordController.text) {
                        return loc.appTitle; // Placeholder: loc.validatorPasswordsDoNotMatch
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
                          label: Text(loc.signUpButtonText), 
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
                      Text(loc.alreadyHaveAccount, style: theme.textTheme.bodyMedium),
                      TextButton(
                        onPressed: _isLoading ? null : _navigateToLogin, 
                        child: Text(loc.loginHereButton, style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.secondary)),
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
