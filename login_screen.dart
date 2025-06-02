import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Added import

// Placeholder SignUpScreen for navigation from LoginScreen
// In a real app, this would be in 'signup_screen.dart' and imported.
class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!; // Added localization instance
    return Scaffold(
      appBar: AppBar(title: Text(loc.signUpScreenTitle)), // Localized
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
        // ignore: unused_local_variable
        final AuthResponse response = await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: password,
        );

        if (mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(loc.loginSuccessfulSnackbar),
              backgroundColor: Colors.green.shade700,
            ),
          );
        }

      } on AuthException catch (e) {
        if (mounted) {
          String errorMessage = loc.loginFailedSnackbar;
          if (e.message.toLowerCase().contains('invalid login credentials')) {
            errorMessage = loc.loginFailedInvalidCredentialsSnackbar;
          } else if (e.message.toLowerCase().contains('email not confirmed')) {
            errorMessage = loc.loginFailedEmailNotConfirmedSnackbar;
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
              // Assuming a generic error key might be good, or stick to e.toString()
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
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SignUpScreen()),
    );
  }

  void _forgotPassword() {
    if (_isLoading) return;
    final loc = AppLocalizations.of(context)!; // Added localization instance
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      // Assuming a key like "forgotPasswordPlaceholderSnackbar" exists or is added
      SnackBar(content: Text(loc.forgotPasswordButton + " (Action TBD)"), backgroundColor: Colors.blueGrey),
    );
    print('Forgot Password tapped');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final loc = AppLocalizations.of(context)!; // Added localization instance

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.loginScreenTitle),
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
                    loc.appTitle, // Using appTitle for "Welcome Back!" or similar generic welcome
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    loc.loginScreenTitle, // Re-using for tagline or specific welcome
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
                        // Assuming key: "validatorRequiredEmail"
                        return loc.appTitle; // Placeholder, replace with actual loc.validatorRequiredEmail
                      }
                      if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(trimmedValue)) {
                        // Assuming key: "validatorInvalidEmail"
                        return loc.appTitle; // Placeholder, replace with actual loc.validatorInvalidEmail
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: loc.passwordLabel,
                      hintText: loc.passwordHintLogin,
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
                        // Assuming key: "validatorRequiredPassword"
                        return loc.appTitle; // Placeholder, replace with actual loc.validatorRequiredPassword
                      }
                      if (value.length < 6) {
                        // Assuming key: "validatorPasswordLength"
                        return loc.appTitle; // Placeholder, replace with actual loc.validatorPasswordLength
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
                      child: Text(loc.forgotPasswordButton, style: TextStyle(color: theme.colorScheme.secondary)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  _isLoading
                      ? const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()))
                      : ElevatedButton.icon(
                          icon: const Icon(Icons.login_rounded),
                          label: Text(loc.loginButtonText.toUpperCase()), // ARB has "Login", toUpperCase for style
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
                      Text(loc.dontHaveAccount, style: theme.textTheme.bodyMedium),
                      TextButton(
                        onPressed: _isLoading ? null : _navigateToSignUp,
                        child: Text(loc.signUpNowButton, style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.secondary)),
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
