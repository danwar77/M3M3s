import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen_l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es')
  ];

  /// The main title of the application
  ///
  /// In en, this message translates to:
  /// **'M3M3s App'**
  String get appTitle;

  /// No description provided for @loginScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Login to M3M3s'**
  String get loginScreenTitle;

  /// No description provided for @signUpScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get signUpScreenTitle;

  /// No description provided for @createMemeWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'M3M3s'**
  String get createMemeWelcomeTitle;

  /// No description provided for @createMemeWelcomeTagline.
  ///
  /// In en, this message translates to:
  /// **'Craft hilarious memes in seconds!'**
  String get createMemeWelcomeTagline;

  /// No description provided for @createMemeButton.
  ///
  /// In en, this message translates to:
  /// **'Create New Meme'**
  String get createMemeButton;

  /// No description provided for @viewHistoryButton.
  ///
  /// In en, this message translates to:
  /// **'View My History'**
  String get viewHistoryButton;

  /// No description provided for @historyScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'My Meme History'**
  String get historyScreenTitle;

  /// No description provided for @textInputScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Your Meme'**
  String get textInputScreenTitle;

  /// No description provided for @memeDisplayScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Preview & Edit Meme'**
  String get memeDisplayScreenTitle;

  /// No description provided for @selectTemplateTitle.
  ///
  /// In en, this message translates to:
  /// **'Select a Template'**
  String get selectTemplateTitle;

  /// No description provided for @addStickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a Sticker'**
  String get addStickerTitle;

  /// No description provided for @createTabLabel.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get createTabLabel;

  /// No description provided for @historyTabLabel.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTabLabel;

  /// No description provided for @loginButtonText.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginButtonText;

  /// No description provided for @signUpButtonText.
  ///
  /// In en, this message translates to:
  /// **'CREATE ACCOUNT'**
  String get signUpButtonText;

  /// No description provided for @logoutButtonTooltip.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutButtonTooltip;

  /// No description provided for @languageButtonTooltip.
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get languageButtonTooltip;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get emailHint;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @passwordHintLogin.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get passwordHintLogin;

  /// No description provided for @passwordHintSignUp.
  ///
  /// In en, this message translates to:
  /// **'Choose a strong password'**
  String get passwordHintSignUp;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPasswordLabel;

  /// No description provided for @confirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Re-enter your password'**
  String get confirmPasswordHint;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @signUpNowButton.
  ///
  /// In en, this message translates to:
  /// **'Sign Up Now'**
  String get signUpNowButton;

  /// No description provided for @loginHereButton.
  ///
  /// In en, this message translates to:
  /// **'Login Here'**
  String get loginHereButton;

  /// No description provided for @forgotPasswordButton.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPasswordButton;

  /// No description provided for @topTextLabel.
  ///
  /// In en, this message translates to:
  /// **'Top Text (Optional)'**
  String get topTextLabel;

  /// No description provided for @bottomTextLabel.
  ///
  /// In en, this message translates to:
  /// **'Bottom Text (Optional)'**
  String get bottomTextLabel;

  /// No description provided for @chooseTemplateButton.
  ///
  /// In en, this message translates to:
  /// **'Choose Template'**
  String get chooseTemplateButton;

  /// No description provided for @uploadImageButton.
  ///
  /// In en, this message translates to:
  /// **'Upload Custom'**
  String get uploadImageButton;

  /// No description provided for @getSuggestionsButton.
  ///
  /// In en, this message translates to:
  /// **'Get Suggestions & Prepare'**
  String get getSuggestionsButton;

  /// No description provided for @saveButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveButton;

  /// No description provided for @shareButton.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareButton;

  /// No description provided for @addStickerButton.
  ///
  /// In en, this message translates to:
  /// **'Add Sticker'**
  String get addStickerButton;

  /// No description provided for @retryButton.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryButton;

  /// No description provided for @refreshButton.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refreshButton;

  /// No description provided for @selectColorButton.
  ///
  /// In en, this message translates to:
  /// **'Select Color'**
  String get selectColorButton;

  /// No description provided for @cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// No description provided for @loadingTemplates.
  ///
  /// In en, this message translates to:
  /// **'Loading templates...'**
  String get loadingTemplates;

  /// No description provided for @loadingHistory.
  ///
  /// In en, this message translates to:
  /// **'Loading your meme history...'**
  String get loadingHistory;

  /// No description provided for @errorLoadingTemplates.
  ///
  /// In en, this message translates to:
  /// **'Oops! Couldn\'t load templates. Please check your connection and try again.'**
  String get errorLoadingTemplates;

  /// No description provided for @errorLoadingHistory.
  ///
  /// In en, this message translates to:
  /// **'Oops! Could not load your history.'**
  String get errorLoadingHistory;

  /// No description provided for @errorLoginUserNotAuthenticated.
  ///
  /// In en, this message translates to:
  /// **'Please log in to see your meme history.'**
  String get errorLoginUserNotAuthenticated;

  /// No description provided for @noTemplatesFound.
  ///
  /// In en, this message translates to:
  /// **'No templates found.\nTry refreshing or check back later!'**
  String get noTemplatesFound;

  /// No description provided for @noHistoryFound.
  ///
  /// In en, this message translates to:
  /// **'No memes found in your history yet.'**
  String get noHistoryFound;

  /// No description provided for @noHistoryFoundPrompt.
  ///
  /// In en, this message translates to:
  /// **'Go create some awesome memes!'**
  String get noHistoryFoundPrompt;

  /// No description provided for @createFirstMemeButton.
  ///
  /// In en, this message translates to:
  /// **'Create First Meme!'**
  String get createFirstMemeButton;

  /// No description provided for @stickerAddedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Sticker added! Drag to position.'**
  String get stickerAddedSnackbar;

  /// No description provided for @stickerRemovedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Sticker removed.'**
  String get stickerRemovedSnackbar;

  /// Snackbar message when a keyword chip is tapped.
  ///
  /// In en, this message translates to:
  /// **'Keyword \"{keyword}\" tapped. Future: Use for filtering or tagging.'**
  String keywordTappedSnackbar(String keyword);

  /// No description provided for @loadingSuggestionDetailsSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Loading details for \"{templateName}\"...'**
  String loadingSuggestionDetailsSnackbar(String templateName);

  /// No description provided for @templateSelectedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'\"{templateName}\" selected.'**
  String templateSelectedSnackbar(String templateName);

  /// No description provided for @errorLoadingTemplateDetailsSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Error loading details for \"{templateName}\": {errorMessage}'**
  String errorLoadingTemplateDetailsSnackbar(String templateName, String errorMessage);

  /// No description provided for @customImageSelectedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Custom image selected!'**
  String get customImageSelectedSnackbar;

  /// No description provided for @noImageSelectedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'No image selected.'**
  String get noImageSelectedSnackbar;

  /// No description provided for @errorPickingImageSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Error picking image: {errorMessage}'**
  String errorPickingImageSnackbar(String errorMessage);

  /// No description provided for @memeSavedSuccessSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Meme saved successfully!'**
  String get memeSavedSuccessSnackbar;

  /// No description provided for @savingMemeSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Saving meme...'**
  String get savingMemeSnackbar;

  /// No description provided for @errorSavingMemeSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Error saving meme: {errorMessage}'**
  String errorSavingMemeSnackbar(String errorMessage);

  /// No description provided for @preparingShareSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Preparing meme for sharing...'**
  String get preparingShareSnackbar;

  /// No description provided for @errorSharingMemeSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Error sharing meme: {errorMessage}'**
  String errorSharingMemeSnackbar(String errorMessage);

  /// No description provided for @shareDismissedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Sharing dismissed.'**
  String get shareDismissedSnackbar;

  /// No description provided for @shareSuccessSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Meme shared successfully!'**
  String get shareSuccessSnackbar;

  /// No description provided for @loginSuccessfulSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Login successful!'**
  String get loginSuccessfulSnackbar;

  /// No description provided for @loginFailedInvalidCredentialsSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password. Please check your credentials.'**
  String get loginFailedInvalidCredentialsSnackbar;

  /// No description provided for @loginFailedEmailNotConfirmedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your email address before logging in.'**
  String get loginFailedEmailNotConfirmedSnackbar;

  /// No description provided for @loginFailedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Login failed. Please try again.'**
  String get loginFailedSnackbar;

  /// No description provided for @signUpSuccessfulEmailConfirmationSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Sign-up successful! Please check your email to confirm your account.'**
  String get signUpSuccessfulEmailConfirmationSnackbar;

  /// No description provided for @signUpSuccessfulSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Sign-up successful!'**
  String get signUpSuccessfulSnackbar;

  /// No description provided for @signUpFailedUserExistsSnackbar.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered. Please try logging in.'**
  String get signUpFailedUserExistsSnackbar;

  /// No description provided for @signUpFailedWeakPasswordSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Password is too short. It must be at least 6 characters.'**
  String get signUpFailedWeakPasswordSnackbar;

  /// No description provided for @signUpFailedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Sign-up failed. Please try again.'**
  String get signUpFailedSnackbar;

  /// No description provided for @logoutSuccessfulSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Successfully logged out.'**
  String get logoutSuccessfulSnackbar;

  /// No description provided for @logoutFailedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Logout failed: {errorMessage}'**
  String logoutFailedSnackbar(String errorMessage);

  /// No description provided for @placeholderLanguageChangeSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Language change functionality to be implemented!'**
  String get placeholderLanguageChangeSnackbar;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'es': return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
