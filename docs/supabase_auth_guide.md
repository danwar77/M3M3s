# Supabase Authentication Guide for Flutter

This guide provides a comprehensive walkthrough for setting up Supabase Authentication in your Supabase project and integrating it into a Flutter application using the `supabase_flutter` package.

## 1. Introduction to Supabase Auth

Supabase Auth provides a complete solution for user authentication and authorization. It integrates seamlessly with Supabase's database and other services, allowing you to secure your application with Row Level Security (RLS). Key features include email/password authentication, social logins (OAuth), magic links, and automated session management.

## 2. Supabase Project Configuration (Dashboard)

Before integrating with Flutter, you need to configure authentication settings in your Supabase project dashboard.

### 2.1. Enable Authentication
Authentication is typically enabled by default for new Supabase projects. You can verify this by navigating to the "Authentication" section in the Supabase dashboard.

### 2.2. Configure Auth Providers

*   **Email/Password:**
    *   This is often the primary authentication method.
    *   Go to `Authentication` -> `Providers`.
    *   Ensure "Email" is enabled. You can configure options like "Enable email confirmations" here.
*   **(Optional) Social Providers (OAuth):**
    *   Supabase supports various social logins (e.g., Google, GitHub, Apple).
    *   To enable them, navigate to `Authentication` -> `Providers`.
    *   Select the desired provider and follow the instructions to input your client ID and secret obtained from the respective OAuth provider's developer console.

### 2.3. Auth Settings

Navigate to `Authentication` -> `Settings` to configure:

*   **Site URL:**
    *   **Crucial for email confirmation and password reset links.** Set this to your application's primary URL (e.g., `https://myapp.com` or `http://localhost:3000` for local development with deep linking).
*   **Additional Redirect URLs:**
    *   Specify any valid redirect URLs for OAuth providers or other authentication flows. For mobile apps, these are often custom schemes (e.g., `io.supabase.flutterquickstart://login-callback/`).
*   **Email Templates:**
    *   Customize the content of emails sent for user confirmation, password resets, magic links, etc. You can find these under `Authentication` -> `Templates`.
*   **(Optional) Advanced Features:**
    *   **Multi-Factor Authentication (MFA):** Can be enabled under `Authentication` -> `Settings` for enhanced security.
    *   **Secure email change:** Enabled by default.
    *   **Manual Email Confirmations:** If you disable automatic email confirmations, you'll need to handle this flow manually.

## 3. Flutter Client Integration (`supabase_flutter`)

The `supabase_flutter` package makes it easy to interact with Supabase from your Flutter app.

### 3.1. Installation

Add `supabase_flutter` to your `pubspec.yaml` file:

```yaml
dependencies:
  flutter:
    sdk: flutter
  supabase_flutter: ^2.0.0 # Use the latest version
```
Then run `flutter pub get`.

### 3.2. Initialization

Initialize the Supabase client in your `main.dart` file, preferably before `runApp()`.

```dart
// main.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Required for Supabase init

  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Supabase Auth Demo',
      home: AuthPage(), // Your initial page
    );
  }
}
```

**Best Practices for Storing URL and Anon Key:**
Avoid hardcoding your Supabase URL and Anon Key directly in your source code. Use one of these methods:

*   **Environment Variables with `--dart-define`:**
    Pass them during build/run:
    ```bash
    flutter run --dart-define=SUPABASE_URL=YOUR_URL --dart-define=SUPABASE_ANON_KEY=YOUR_KEY
    ```
    Access them in Dart:
    ```dart
    const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
    const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
    ```
*   **Configuration File (e.g., `config.json`):**
    Create a `config.json` (add to `.gitignore`), load it at runtime, and parse the keys.

### 3.3. Accessing the Client

Once initialized, you can access the Supabase client instance anywhere in your app:

```dart
final supabase = Supabase.instance.client;
// or for brevity: final supabase = Supabase.client;
```

### 3.4. User Sign-Up

Create a function to handle user registration.

```dart
Future<String?> signUpUser({required String email, required String password}) async {
  try {
    final AuthResponse response = await Supabase.instance.client.auth.signUp(
      email: email,
      password: password,
      // Optional: You can add user metadata here
      // data: {'username': 'my_username'}, 
    );
    if (response.user != null) {
      // Check if email confirmation is required
      if (response.user!.identities?.isEmpty ?? true) { // Or check a specific flag if Supabase provides one
         return 'Confirmation email sent. Please check your inbox.';
      }
      return 'Sign up successful! User ID: ${response.user!.id}';
    } else if (response.session == null && response.user == null) {
      // This case might occur if email confirmation is enabled and the user already exists but is unconfirmed.
      // Supabase might not return an error but also no user/session.
      return 'User may already exist or confirmation pending. Please check your email or try logging in.';
    }
  } on AuthException catch (e) {
    return 'Sign up failed: ${e.message}';
  } catch (e) {
    return 'An unexpected error occurred: ${e.toString()}';
  }
  return null; // Should not reach here if logic is sound
}
```
**Handling Responses:**
*   **Success:** `response.user` will contain the user object. If email confirmation is enabled, the user needs to verify their email before they can log in.
*   **Error:** `AuthException` provides error details.

### 3.5. User Sign-In

Create a function for user login.

```dart
Future<String?> signInUser({required String email, required String password}) async {
  try {
    final AuthResponse response = await Supabase.instance.client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    if (response.user != null) {
      return 'Sign in successful! User ID: ${response.user!.id}';
    }
  } on AuthException catch (e) {
    if (e.message.toLowerCase().contains('email not confirmed')) {
        return 'Email not confirmed. Please check your inbox for the confirmation link.';
    }
    return 'Sign in failed: ${e.message}';
  } catch (e) {
    return 'An unexpected error occurred: ${e.toString()}';
  }
  return 'Sign in failed. Please check your credentials.';
}
```
**Handling Responses:**
*   **Success:** `response.user` and `response.session` will be populated.
*   **Error:** `AuthException` provides error details (e.g., invalid credentials, email not confirmed).

### 3.6. User Sign-Out

Create a function to log users out.

```dart
Future<String?> signOutUser() async {
  try {
    await Supabase.instance.client.auth.signOut();
    return 'Sign out successful.';
  } on AuthException catch (e) {
    return 'Sign out failed: ${e.message}';
  } catch (e) {
    return 'An unexpected error occurred during sign out: ${e.toString()}';
  }
}
```

### 3.7. Listening to Auth State Changes

Supabase provides a stream to listen for authentication events (sign-in, sign-out, token refresh, etc.). This is crucial for managing app navigation and UI updates.

```dart
// Example: In your main widget or a dedicated auth state manager
StreamSubscription<AuthState> _authStateSubscription;

@override
void initState() {
  super.initState();
  _authStateSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((AuthState data) {
    final AuthChangeEvent event = data.event;
    final Session? session = data.session;

    print('Auth event: $event, Session: ${session?.toJson()}');

    if (event == AuthChangeEvent.signedIn) {
      // Navigate to home screen or update UI
      // e.g., Navigator.of(context).pushReplacementNamed('/home');
    } else if (event == AuthChangeEvent.signedOut) {
      // Navigate to login screen or update UI
      // e.g., Navigator.of(context).pushReplacementNamed('/login');
    } else if (event == AuthChangeEvent.tokenRefreshed) {
      // Session token has been refreshed.
      // You might not need to do anything specific here as the client handles it.
    } else if (event == AuthChangeEvent.userUpdated) {
      // User details have been updated.
    } else if (event == AuthChangeEvent.passwordRecovery) {
        // User is in password recovery flow
    }
  });
}

@override
void dispose() {
  _authStateSubscription.cancel();
  super.dispose();
}
```

**Usage with State Management:**
This stream is commonly used with state management solutions like Provider, Riverpod, or BLoC. You can expose the `User` object or authentication status through your state management system and have widgets rebuild accordingly.

**Example with `StreamBuilder` for simple navigation:**

```dart
// In your root widget or navigation handler
class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final session = snapshot.data?.session;
          if (session != null) {
            return HomeScreen(); // User is logged in
          } else {
            return LoginScreen(); // User is logged out
          }
        }
        return Scaffold(body: Center(child: CircularProgressIndicator())); // Loading or initial state
      },
    );
  }
}
```

### 3.8. Session Management

The `supabase_flutter` package automatically handles session persistence (stores the session securely on the device) and token refreshing. You generally don't need to manage tokens manually. The `onAuthStateChange` stream will notify you of `AuthChangeEvent.tokenRefreshed` events.

### 3.9. Accessing User Information

You can get the currently logged-in user's details at any time:

```dart
final currentUser = Supabase.instance.client.auth.currentUser;

if (currentUser != null) {
  print('Current User ID: ${currentUser.id}');
  print('Current User Email: ${currentUser.email}');
  print('User App Metadata: ${currentUser.appMetadata}'); // Custom data set during sign up or update
  print('User Metadata: ${currentUser.userMetadata}'); // From social providers or updated manually
}
```

## 4. Linking Auth to Row Level Security (RLS)

Supabase's powerful RLS allows you to define data access policies based on the authenticated user. In your SQL RLS policies, you typically use `auth.uid()` to get the ID of the currently authenticated user making the request.

**Example RLS Policy:**
This policy ensures that users can only select their own profile from the `profiles` table.

```sql
-- (From schema.sql)
-- Enable RLS on the table first
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Policy: Users can select their own profile.
CREATE POLICY "Users can select their own profile."
ON public.profiles
FOR SELECT
USING (auth.uid() = id);
```
When a Flutter client authenticated with Supabase makes a request to fetch data from the `profiles` table, Supabase uses the user's JWT to determine `auth.uid()` and applies the RLS policy accordingly.

## 5. Automating Profile Creation (Trigger)

It's common to have a public `profiles` table that stores additional user information not present in `auth.users` (which is in a protected schema). You can automate the creation of a profile entry when a new user signs up using a database trigger.

**SQL Trigger Function:**
This function, when triggered, inserts a new row into `public.profiles` using the new user's ID and email from `auth.users`.

```sql
-- (From schema.sql)
-- Function to create a profile for a new user
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, username, app_preferences) -- Added app_preferences
  VALUES (
    NEW.id, 
    COALESCE(NEW.raw_user_meta_data->>'username', NEW.email), -- Use username from metadata if available, else email
    '{"theme": "system", "notifications_enabled": true}'::jsonb -- Example default preferences
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to call the function after a new user is inserted into auth.users
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
```
**Note:**
*   `SECURITY DEFINER`: This allows the function to run with the permissions of the user who defined it (usually a superuser or admin), enabling it to write to `public.profiles` even if the new user doesn't have direct insert permissions yet.
*   `NEW.raw_user_meta_data->>'username'`: This attempts to pull a username if it was provided in the `data` field during `signUp`. Adjust as needed.
*   Ensure this trigger is created in your Supabase SQL editor.

## 6. Error Handling and Best Practices

*   **Comprehensive Error Handling:** Always wrap Supabase calls in `try-catch` blocks to handle `AuthException` and other potential errors gracefully. Provide user-friendly feedback.
*   **Loading States:** Show loading indicators during async operations (sign-up, sign-in, sign-out).
*   **Input Validation:** Validate email and password formats on the client-side before sending them to Supabase.
*   **Secure Keys:** Do not expose your Supabase Service Role Key in the Flutter app. Only the Anon Key should be used.
*   **Deep Linking for Email Confirmation:** For mobile apps, configure deep linking (universal links for iOS, app links for Android) so that email confirmation and password reset links can redirect users back to your app. The "Site URL" and "Redirect URLs" in Supabase Auth settings are critical for this.
*   **State Management:** Use a robust state management solution to manage authentication state and user data throughout your application.
*   **Regularly Update `supabase_flutter`:** Keep the package updated to the latest version for security patches and new features.

This guide should provide a solid foundation for implementing Supabase authentication in your Flutter application. Refer to the official [Supabase Flutter documentation](https://supabase.io/docs/guides/getting-started/tutorials/with-flutter) for more details and advanced use cases.
```
