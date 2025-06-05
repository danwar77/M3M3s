// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'M3M3s App';

  @override
  String get loginScreenTitle => 'Login to M3M3s';

  @override
  String get signUpScreenTitle => 'Create Account';

  @override
  String get createMemeWelcomeTitle => 'M3M3s';

  @override
  String get createMemeWelcomeTagline => 'Craft hilarious memes in seconds!';

  @override
  String get createMemeButton => 'Create New Meme';

  @override
  String get viewHistoryButton => 'View My History';

  @override
  String get historyScreenTitle => 'My Meme History';

  @override
  String get textInputScreenTitle => 'Create Your Meme';

  @override
  String get memeDisplayScreenTitle => 'Preview & Edit Meme';

  @override
  String get selectTemplateTitle => 'Select a Template';

  @override
  String get addStickerTitle => 'Add a Sticker';

  @override
  String get createTabLabel => 'Create';

  @override
  String get historyTabLabel => 'History';

  @override
  String get loginButtonText => 'Login';

  @override
  String get signUpButtonText => 'CREATE ACCOUNT';

  @override
  String get logoutButtonTooltip => 'Logout';

  @override
  String get languageButtonTooltip => 'Change Language';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailHint => 'you@example.com';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordHintLogin => 'Enter your password';

  @override
  String get passwordHintSignUp => 'Choose a strong password';

  @override
  String get confirmPasswordLabel => 'Confirm Password';

  @override
  String get confirmPasswordHint => 'Re-enter your password';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get signUpNowButton => 'Sign Up Now';

  @override
  String get loginHereButton => 'Login Here';

  @override
  String get forgotPasswordButton => 'Forgot Password?';

  @override
  String get topTextLabel => 'Top Text (Optional)';

  @override
  String get bottomTextLabel => 'Bottom Text (Optional)';

  @override
  String get chooseTemplateButton => 'Choose Template';

  @override
  String get uploadImageButton => 'Upload Custom';

  @override
  String get getSuggestionsButton => 'Get Suggestions & Prepare';

  @override
  String get saveButton => 'Save';

  @override
  String get shareButton => 'Share';

  @override
  String get addStickerButton => 'Add Sticker';

  @override
  String get retryButton => 'Retry';

  @override
  String get refreshButton => 'Refresh';

  @override
  String get selectColorButton => 'Select Color';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get loadingTemplates => 'Loading templates...';

  @override
  String get loadingHistory => 'Loading your meme history...';

  @override
  String get errorLoadingTemplates => 'Oops! Couldn\'t load templates. Please check your connection and try again.';

  @override
  String get errorLoadingHistory => 'Oops! Could not load your history.';

  @override
  String get errorLoginUserNotAuthenticated => 'Please log in to see your meme history.';

  @override
  String get noTemplatesFound => 'No templates found.\nTry refreshing or check back later!';

  @override
  String get noHistoryFound => 'No memes found in your history yet.';

  @override
  String get noHistoryFoundPrompt => 'Go create some awesome memes!';

  @override
  String get createFirstMemeButton => 'Create First Meme!';

  @override
  String get stickerAddedSnackbar => 'Sticker added! Drag to position.';

  @override
  String get stickerRemovedSnackbar => 'Sticker removed.';

  @override
  String keywordTappedSnackbar(String keyword) {
    return 'Keyword \"$keyword\" tapped. Future: Use for filtering or tagging.';
  }

  @override
  String loadingSuggestionDetailsSnackbar(String templateName) {
    return 'Loading details for \"$templateName\"...';
  }

  @override
  String templateSelectedSnackbar(String templateName) {
    return '\"$templateName\" selected.';
  }

  @override
  String errorLoadingTemplateDetailsSnackbar(String templateName, String errorMessage) {
    return 'Error loading details for \"$templateName\": $errorMessage';
  }

  @override
  String get customImageSelectedSnackbar => 'Custom image selected!';

  @override
  String get noImageSelectedSnackbar => 'No image selected.';

  @override
  String errorPickingImageSnackbar(String errorMessage) {
    return 'Error picking image: $errorMessage';
  }

  @override
  String get memeSavedSuccessSnackbar => 'Meme saved successfully!';

  @override
  String get savingMemeSnackbar => 'Saving meme...';

  @override
  String errorSavingMemeSnackbar(String errorMessage) {
    return 'Error saving meme: $errorMessage';
  }

  @override
  String get preparingShareSnackbar => 'Preparing meme for sharing...';

  @override
  String errorSharingMemeSnackbar(String errorMessage) {
    return 'Error sharing meme: $errorMessage';
  }

  @override
  String get shareDismissedSnackbar => 'Sharing dismissed.';

  @override
  String get shareSuccessSnackbar => 'Meme shared successfully!';

  @override
  String get loginSuccessfulSnackbar => 'Login successful!';

  @override
  String get loginFailedInvalidCredentialsSnackbar => 'Invalid email or password. Please check your credentials.';

  @override
  String get loginFailedEmailNotConfirmedSnackbar => 'Please confirm your email address before logging in.';

  @override
  String get loginFailedSnackbar => 'Login failed. Please try again.';

  @override
  String get signUpSuccessfulEmailConfirmationSnackbar => 'Sign-up successful! Please check your email to confirm your account.';

  @override
  String get signUpSuccessfulSnackbar => 'Sign-up successful!';

  @override
  String get signUpFailedUserExistsSnackbar => 'This email is already registered. Please try logging in.';

  @override
  String get signUpFailedWeakPasswordSnackbar => 'Password is too short. It must be at least 6 characters.';

  @override
  String get signUpFailedSnackbar => 'Sign-up failed. Please try again.';

  @override
  String get logoutSuccessfulSnackbar => 'Successfully logged out.';

  @override
  String logoutFailedSnackbar(String errorMessage) {
    return 'Logout failed: $errorMessage';
  }

  @override
  String get placeholderLanguageChangeSnackbar => 'Language change functionality to be implemented!';
}
