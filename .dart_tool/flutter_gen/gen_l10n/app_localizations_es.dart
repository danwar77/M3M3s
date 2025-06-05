// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'M3M3s App [es]';

  @override
  String get loginScreenTitle => 'Iniciar Sesión en M3M3s [es]';

  @override
  String get signUpScreenTitle => 'Crear Cuenta [es]';

  @override
  String get createMemeWelcomeTitle => 'M3M3s [es]';

  @override
  String get createMemeWelcomeTagline => '¡Crea memes divertidos en segundos! [es]';

  @override
  String get createMemeButton => 'Crear Nuevo Meme [es]';

  @override
  String get viewHistoryButton => 'Ver Mi Historial [es]';

  @override
  String get historyScreenTitle => 'Mi Historial de Memes [es]';

  @override
  String get textInputScreenTitle => 'Crea Tu Meme [es]';

  @override
  String get memeDisplayScreenTitle => 'Vista Previa y Editar Meme [es]';

  @override
  String get selectTemplateTitle => 'Seleccionar Plantilla [es]';

  @override
  String get addStickerTitle => 'Añadir Sticker [es]';

  @override
  String get createTabLabel => 'Crear [es]';

  @override
  String get historyTabLabel => 'Historial [es]';

  @override
  String get loginButtonText => 'Iniciar Sesión [es]';

  @override
  String get signUpButtonText => 'CREAR CUENTA [es]';

  @override
  String get logoutButtonTooltip => 'Cerrar Sesión [es]';

  @override
  String get languageButtonTooltip => 'Cambiar Idioma [es]';

  @override
  String get emailLabel => 'Correo Electrónico [es]';

  @override
  String get emailHint => 'tu@ejemplo.com [es]';

  @override
  String get passwordLabel => 'Contraseña [es]';

  @override
  String get passwordHintLogin => 'Ingresa tu contraseña [es]';

  @override
  String get passwordHintSignUp => 'Elige una contraseña segura [es]';

  @override
  String get confirmPasswordLabel => 'Confirmar Contraseña [es]';

  @override
  String get confirmPasswordHint => 'Vuelve a ingresar tu contraseña [es]';

  @override
  String get dontHaveAccount => '¿No tienes una cuenta? [es]';

  @override
  String get alreadyHaveAccount => '¿Ya tienes una cuenta? [es]';

  @override
  String get signUpNowButton => 'Regístrate Ahora [es]';

  @override
  String get loginHereButton => 'Inicia Sesión Aquí [es]';

  @override
  String get forgotPasswordButton => '¿Olvidaste tu contraseña? [es]';

  @override
  String get topTextLabel => 'Texto Superior (Opcional) [es]';

  @override
  String get bottomTextLabel => 'Texto Inferior (Opcional) [es]';

  @override
  String get chooseTemplateButton => 'Elegir Plantilla [es]';

  @override
  String get uploadImageButton => 'Subir Imagen [es]';

  @override
  String get getSuggestionsButton => 'Obtener Sugerencias y Preparar [es]';

  @override
  String get saveButton => 'Guardar [es]';

  @override
  String get shareButton => 'Compartir [es]';

  @override
  String get addStickerButton => 'Añadir Sticker [es]';

  @override
  String get retryButton => 'Reintentar [es]';

  @override
  String get refreshButton => 'Actualizar [es]';

  @override
  String get selectColorButton => 'Seleccionar Color [es]';

  @override
  String get cancelButton => 'Cancelar [es]';

  @override
  String get loadingTemplates => 'Cargando plantillas... [es]';

  @override
  String get loadingHistory => 'Cargando tu historial de memes... [es]';

  @override
  String get errorLoadingTemplates => '¡Ups! No se pudieron cargar las plantillas. Por favor, revisa tu conexión e inténtalo de nuevo. [es]';

  @override
  String get errorLoadingHistory => '¡Ups! No se pudo cargar tu historial. [es]';

  @override
  String get errorLoginUserNotAuthenticated => 'Por favor, inicia sesión para ver tu historial de memes. [es]';

  @override
  String get noTemplatesFound => 'No se encontraron plantillas.\n¡Intenta actualizar o revisa más tarde! [es]';

  @override
  String get noHistoryFound => 'Aún no hay memes en tu historial. [es]';

  @override
  String get noHistoryFoundPrompt => '¡Anímate y crea memes geniales! [es]';

  @override
  String get createFirstMemeButton => '¡Crear Primer Meme! [es]';

  @override
  String get stickerAddedSnackbar => '¡Sticker añadido! Arrástralo para posicionarlo. [es]';

  @override
  String get stickerRemovedSnackbar => 'Sticker eliminado. [es]';

  @override
  String keywordTappedSnackbar(String keyword) {
    return 'Palabra clave \"$keyword\" tocada. Futuro: Usar para filtrar o etiquetar. [es]';
  }

  @override
  String loadingSuggestionDetailsSnackbar(String templateName) {
    return 'Cargando detalles para \"$templateName\"... [es]';
  }

  @override
  String templateSelectedSnackbar(String templateName) {
    return '\"$templateName\" seleccionada. [es]';
  }

  @override
  String errorLoadingTemplateDetailsSnackbar(String templateName, String errorMessage) {
    return 'Error al cargar detalles para \"$templateName\": $errorMessage [es]';
  }

  @override
  String get customImageSelectedSnackbar => '¡Imagen personalizada seleccionada! [es]';

  @override
  String get noImageSelectedSnackbar => 'Ninguna imagen seleccionada. [es]';

  @override
  String errorPickingImageSnackbar(String errorMessage) {
    return 'Error al seleccionar imagen: $errorMessage [es]';
  }

  @override
  String get memeSavedSuccessSnackbar => '¡Meme guardado con éxito! [es]';

  @override
  String get savingMemeSnackbar => 'Guardando meme... [es]';

  @override
  String errorSavingMemeSnackbar(String errorMessage) {
    return 'Error al guardar meme: $errorMessage [es]';
  }

  @override
  String get preparingShareSnackbar => 'Preparando meme para compartir... [es]';

  @override
  String errorSharingMemeSnackbar(String errorMessage) {
    return 'Error al compartir meme: $errorMessage [es]';
  }

  @override
  String get shareDismissedSnackbar => 'Compartir cancelado. [es]';

  @override
  String get shareSuccessSnackbar => '¡Meme compartido con éxito! [es]';

  @override
  String get loginSuccessfulSnackbar => '¡Inicio de sesión exitoso! [es]';

  @override
  String get loginFailedInvalidCredentialsSnackbar => 'Correo o contraseña incorrectos. Por favor, verifica tus credenciales. [es]';

  @override
  String get loginFailedEmailNotConfirmedSnackbar => 'Por favor, confirma tu correo electrónico antes de iniciar sesión. [es]';

  @override
  String get loginFailedSnackbar => 'Falló el inicio de sesión. Por favor, inténtalo de nuevo. [es]';

  @override
  String get signUpSuccessfulEmailConfirmationSnackbar => '¡Registro exitoso! Por favor, revisa tu correo para confirmar tu cuenta. [es]';

  @override
  String get signUpSuccessfulSnackbar => '¡Registro exitoso! [es]';

  @override
  String get signUpFailedUserExistsSnackbar => 'Este correo ya está registrado. Por favor, intenta iniciar sesión. [es]';

  @override
  String get signUpFailedWeakPasswordSnackbar => 'La contraseña es muy corta. Debe tener al menos 6 caracteres. [es]';

  @override
  String get signUpFailedSnackbar => 'Falló el registro. Por favor, inténtalo de nuevo. [es]';

  @override
  String get logoutSuccessfulSnackbar => 'Sesión cerrada exitosamente. [es]';

  @override
  String logoutFailedSnackbar(String errorMessage) {
    return 'Falló el cierre de sesión: $errorMessage [es]';
  }

  @override
  String get placeholderLanguageChangeSnackbar => '¡Funcionalidad de cambio de idioma por implementar! [es]';
}
