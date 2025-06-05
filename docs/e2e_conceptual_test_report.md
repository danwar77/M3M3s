# End-to-End Conceptual Test Report: M3M3s Application

## Date: 2025-05-31

This document details the conceptual walkthrough of key end-to-end user scenarios for the M3M3s application, as defined in `e2e_test_scenarios.md`. The purpose of this conceptual test is to verify the logical flow of user interactions, state management, data handling, and error recovery mechanisms across the application's primary features before extensive live testing or further development.

---

## Scenario A: New User Journey (Template Meme)

**Objective:** Verify the end-to-end flow for a new user signing up, creating a meme using a predefined template, saving it, viewing it in their history, and then logging out.

---

**Step A.1: App Start & Sign-Up**

1.  **User Action:** User starts the app for the first time.
    *   **Expected Screen:** `LoginScreen` (assuming `MemeApp`'s initial state with no session navigates here).
    *   **Key Methods:** `MemeApp._MemeAppState.initState()` (listens to `onAuthStateChange`), `Supabase.instance.client.auth.currentSession` (likely null).
    *   **State Changes:** `_MemeAppState._session` (remains null or becomes null), `_MemeAppState._isLoading` (initially true, then false).
    *   **Supabase Interactions:** Minimal, session check.
    *   **UI Feedback:** Splash screen (if any), then `LoginScreen` UI.

2.  **User Action:** User taps the "Don't have an account? Sign Up" link.
    *   **Expected Screen:** `SignUpScreen`.
    *   **Key Methods:** `LoginScreen._navigateToSignUp()` (calls `Navigator.push`).
    *   **State Changes:** None specific to `LoginScreen` state after navigation.
    *   **Supabase Interactions:** None.
    *   **UI Feedback:** Navigation transition to `SignUpScreen`.

3.  **User Action:** User enters email, password, and confirm password on `SignUpScreen` and taps "Sign Up".
    *   **Expected Screen:** `SignUpScreen`.
    *   **Key Methods:** `SignUpScreen._performSignUp()`, `Supabase.instance.client.auth.signUp()`.
    *   **State Changes:** `_SignUpScreenState._isLoading = true` during the call.
    *   **Supabase Interactions:** `auth.signUp` called with email and password.
    *   **UI Feedback:** Loading indicator on "Sign Up" button.
        *   **On Success (e.g., email confirmation required):** `SnackBar` "Sign up successful! Please check your email to confirm." (or similar). Navigation to `LoginScreen` (or stays on `SignUpScreen` with message).
        *   **On Error (e.g., email already exists):** `SnackBar` with error message (e.g., "User already registered"). `_SignUpScreenState._isLoading = false`.

4.  **User Action (Out-of-app):** User confirms their email.
    *   **Expected Screen:** N/A (user is in their email client).
    *   **Supabase Interactions:** Supabase backend handles email confirmation, marks user email as confirmed.

---

**Step A.2: Login**

1.  **User Action:** User navigates to/is on `LoginScreen`, enters credentials, and taps "Login".
    *   **Expected Screen:** `LoginScreen`.
    *   **Key Methods:** `LoginScreen._performLogin()`, `Supabase.instance.client.auth.signInWithPassword()`.
    *   **State Changes:** `_LoginScreenState._isLoading = true` during the call.
    *   **Supabase Interactions:** `auth.signInWithPassword` called.
    *   **UI Feedback:** Loading indicator on "Login" button.
        *   **On Success:** `_LoginScreenState._isLoading = false`. `MemeApp._MemeAppState`'s `onAuthStateChange` listener fires. `_session` updates. Navigation to `MainScreen`.
        *   **On Error (e.g., invalid credentials, email not confirmed yet):** `SnackBar` with error message (e.g., "Invalid login credentials", "Please confirm your email address."). `_LoginScreenState._isLoading = false`.

---

**Step A.3: Meme Creation (Template)**

1.  **User Action:** User is on `MainScreen`, "Create" tab is selected by default, showing `CreateScreen`. User taps "Create New Meme".
    *   **Expected Screen:** `CreateScreen` (initial view within `MainScreen`), then navigates to `TextInputScreen`.
    *   **Key Methods:** `CreateScreen` button `onPressed` calls `Navigator.push` to `TextInputScreen`.
    *   **State Changes (Conceptual):** Tab index in `MainScreen` remains on "Create".
    *   **Supabase Interactions:** None.
    *   **UI Feedback:** Transition to `TextInputScreen`.

2.  **User Action:** On `TextInputScreen`, user taps "Choose from Templates".
    *   **Expected Screen:** `TextInputScreen`. A modal bottom sheet (template browser) appears.
    *   **Key Methods:** `TextInputScreen._selectTemplate()`, `TextInputScreen._fetchTemplates(isInitialFetch: true)` (if not already loaded).
    *   **State Changes:** `_TextInputScreenState._isLoadingTemplates = true` initially. `_TextInputScreenState._allFetchedTemplates` populated.
    *   **Supabase Interactions:** `supabase.from('templates').select().range()` if templates are fetched.
    *   **UI Feedback:** Modal bottom sheet slides up. Loading indicator for templates, then `GridView` of `TemplateListItem`s.

3.  **User Action:** User scrolls the template browser (if many templates) and selects a template.
    *   **Expected Screen:** `TextInputScreen` (modal bottom sheet).
    *   **Key Methods:** `_templateScrollController` listener in `TextInputScreen` might call `_fetchTemplates()` for pagination. `TemplateListItem.onTap` callback is invoked.
    *   **State Changes:** `_TextInputScreenState._selectedTemplateId`, `_TextInputScreenState._selectedTemplateName`, `_TextInputScreenState._selectedTemplateImageUrl` update. `_TextInputScreenState._customImageFile` is cleared. `_TextInputScreenState._showSuggestionsCard = false`. Modal dismisses.
    *   **Supabase Interactions:** Potential further template fetches if paginating.
    *   **UI Feedback:** Selected template's image and name appear in the main `TextInputScreen` UI. Template browser dismisses.

4.  **User Action:** User enters top and bottom text.
    *   **Expected Screen:** `TextInputScreen`.
    *   **Key Methods:** `TextFormField.onChanged` updates internal controllers/state for text.
    *   **State Changes:** `_TextInputScreenState._topText`, `_TextInputScreenState._bottomText` update.
    *   **Supabase Interactions:** None.
    *   **UI Feedback:** Text appears in the input fields.

5.  **User Action:** User taps "Get Suggestions & Prepare".
    *   **Expected Screen:** `TextInputScreen`.
    *   **Key Methods:** `TextInputScreen._processMeme()`. If text is present, may call `_getMemeSuggestions()`.
    *   **State Changes:** `_TextInputScreenState._isLoadingSuggestions = true` if suggestions are fetched. `_TextInputScreenState._showSuggestionsCard = true` (or false if error/no suggestions).
    *   **Supabase Interactions:** (If suggestions enabled) `supabase.functions.invoke('get-meme-suggestions')`.
    *   **UI Feedback:** Loading indicator for suggestions (if applicable). Suggestions card appears (or error message).
        *   *For this scenario, assume user ignores suggestions or they are optional and proceeds.*

6.  **User Action (Proceeding after suggestions or if no suggestions):** The `_processMeme()` method, after handling suggestions (or skipping), navigates to `MemeDisplayScreen`.
    *   **Expected Screen:** `MemeDisplayScreen`.
    *   **Key Methods:** `Navigator.push` with `MemeData` (containing selected template URL, entered text).
    *   **State Changes:** None in `TextInputScreen` after navigation. `MemeDisplayScreen` initializes with passed `MemeData`.
    *   **Supabase Interactions:** None.
    *   **UI Feedback:** Transition to `MemeDisplayScreen`. Meme preview shown using template image and overlaid text.

---

**Step A.4: Meme Finalization & Saving**

1.  **User Action:** User verifies meme preview on `MemeDisplayScreen`.
    *   **Expected Screen:** `MemeDisplayScreen`.
    *   **Key Methods:** `MemeDisplayScreen._buildMemePreview()`.
    *   **State Changes:** None.
    *   **Supabase Interactions:** None.
    *   **UI Feedback:** Meme correctly displayed with text overlay. Editing controls visible.

2.  **User Action (Optional):** User makes minor edits (e.g., font size).
    *   **Expected Screen:** `MemeDisplayScreen`.
    *   **Key Methods:** Handlers for editing controls (`_onFontSizeChanged`, etc.).
    *   **State Changes:** `_MemeDisplayScreenState` variables for text style update (`_fontSize`, `_textColor`, etc.). `setState` rebuilds preview.
    *   **Supabase Interactions:** None.
    *   **UI Feedback:** Meme preview updates in real-time.

3.  **User Action:** User taps "Save".
    *   **Expected Screen:** `MemeDisplayScreen`.
    *   **Key Methods:** `MemeDisplayScreen._saveMeme()`. This involves:
        *   Capturing widget using `RepaintBoundary` (`_captureWidgetAsBytes()`).
        *   Uploading image bytes to Supabase Storage (`supabase.storage.from('user_memes').uploadBinary()`).
        *   Saving metadata (image URL from storage, text, user ID, template ID) to Supabase Database (`supabase.from('memes').insert()`).
    *   **State Changes:** `_MemeDisplayScreenState._isSaving = true` during operation, then `false`.
    *   **Supabase Interactions:**
        *   `storage.uploadBinary` to `user_memes` bucket.
        *   `database.insert` into `memes` table.
    *   **UI Feedback:** Loading indicator (e.g., on Save button or overlay). `SnackBar` "Meme saved successfully!" on success. `SnackBar` with error on failure.

---

**Step A.5: View in History**

1.  **User Action:** User navigates to the "History" tab.
    *   **Expected Screen:** `HistoryScreen` (within `MainScreen`).
    *   **Key Methods:** `MainScreen._onItemTapped(1)`. `HistoryScreen._HistoryScreenState.initState()` (if first time viewing) or `build()` method if already initialized.
    *   **State Changes (`HistoryScreen`):**
        *   If first time or `_allHistoryMemes` is empty: `_fetchMemeHistory(isInitialFetch: true)` is called from `initState`.
        *   `_isLoadingInitialHistory = true`.
        *   (If fetch successful) `_allHistoryMemes` populated, `_isLoadingInitialHistory = false`.
    *   **Supabase Interactions:** `supabase.from('memes').select().eq('user_id', ...).order(...).range(...)`.
    *   **UI Feedback:** "Loading your meme history..." if fetching. Then, `GridView` displays memes. The newly saved meme should appear at the top (or based on sort order, typically newest first).

2.  **User Action:** User verifies the newly saved meme is present.
    *   **Expected Screen:** `HistoryScreen`.
    *   **Key Methods:** `GridView.builder` renders items.
    *   **State Changes:** None.
    *   **Supabase Interactions:** None for this specific action.
    *   **UI Feedback:** The meme card for the saved meme is visible with its image and details.

---

**Step A.6: Logout**

1.  **User Action:** User taps the "Logout" button (likely in `MainScreen`'s AppBar or a settings menu).
    *   **Expected Screen:** `MainScreen` (then navigates to `LoginScreen`).
    *   **Key Methods:** `MainScreen._performLogout()`, `Supabase.instance.client.auth.signOut()`.
    *   **State Changes:** `_MainScreenState._isLoggingOut = true` (if such a flag exists). `MemeApp._MemeAppState._session` becomes null via `onAuthStateChange` listener.
    *   **Supabase Interactions:** `auth.signOut()`.
    *   **UI Feedback:** Confirmation dialog for logout. Loading indicator. Screen transitions to `LoginScreen`.

---
---

## Scenario B: Existing User Journey (Custom Image Meme & Share)

**Objective:** Verify the end-to-end flow for an existing user logging in, creating a meme using a custom image uploaded from their device, sharing it, optionally saving it, and then logging out.

---

**Step B.1: App Start & Login**

1.  **User Action:** User starts the app. They have previously signed up and logged out.
    *   **Expected Screen:** `LoginScreen`.
    *   **Key Methods:** `MemeApp._MemeAppState.initState()`, `Supabase.instance.client.auth.currentSession` (null).
    *   **State Changes:** `_MemeAppState._session` (null).
    *   **Supabase Interactions:** Session check.
    *   **UI Feedback:** `LoginScreen` UI.

2.  **User Action:** User enters their existing credentials and taps "Login".
    *   **Expected Screen:** `LoginScreen`.
    *   **Key Methods:** `LoginScreen._performLogin()`, `Supabase.instance.client.auth.signInWithPassword()`.
    *   **State Changes:** `_LoginScreenState._isLoading = true`.
    *   **Supabase Interactions:** `auth.signInWithPassword`.
    *   **UI Feedback:** Loading indicator. On success, navigation to `MainScreen`. `_MemeAppState._session` updates. On failure, `SnackBar` with error.

---

**Step B.2: Meme Creation (Custom Image)**

1.  **User Action:** On `MainScreen` (defaults to `CreateScreen`), user taps "Create New Meme".
    *   **Expected Screen:** Navigates to `TextInputScreen`.
    *   **Key Methods:** `CreateScreen` button `onPressed` -> `Navigator.push`.
    *   **UI Feedback:** Transition to `TextInputScreen`.

2.  **User Action:** On `TextInputScreen`, user taps "Upload Image".
    *   **Expected Screen:** `TextInputScreen`. A modal bottom sheet (`_showImageSourceSelection()`) or directly an image picker appears.
    *   **Key Methods:** `TextInputScreen._pickCustomImage()`, `ImagePicker().pickImage()`.
    *   **State Changes:** None directly from tapping "Upload Image", but subsequent actions will update state.
    *   **Supabase Interactions:** None.
    *   **UI Feedback:** Image source selection UI (Gallery/Camera).

3.  **User Action:** User selects an image from their device gallery or camera.
    *   **Expected Screen:** `TextInputScreen`.
    *   **Key Methods:** `_pickCustomImage()` continues.
    *   **State Changes:** `_TextInputScreenState._customImageFile` updates with the selected `File`. `_TextInputScreenState._selectedTemplateId` (and related template fields) are cleared. `_TextInputScreenState._showSuggestionsCard = false`.
    *   **Supabase Interactions:** None.
    *   **UI Feedback:** The selected custom image is displayed in the preview area on `TextInputScreen`. Template selection area is cleared/reset.

4.  **User Action:** User enters top and bottom text.
    *   **Expected Screen:** `TextInputScreen`.
    *   **Key Methods:** `TextFormField.onChanged`.
    *   **State Changes:** `_TextInputScreenState._topText`, `_TextInputScreenState._bottomText` update.
    *   **Supabase Interactions:** None.
    *   **UI Feedback:** Text appears in the input fields.

5.  **User Action:** User taps "Get Suggestions & Prepare".
    *   **Expected Screen:** `TextInputScreen`.
    *   **Key Methods:** `TextInputScreen._processMeme()`.
        *   Since `_customImageFile` is present, it should *not* attempt to fetch AI suggestions based on text alone (current design focus for suggestions is template-driven, this might be a point of review/clarification if AI suggestions are desired for custom images too). Assuming suggestions are skipped or not applicable here.
    *   **State Changes:** `_TextInputScreenState._isLoadingSuggestions` (likely remains false or briefly true then false).
    *   **Supabase Interactions:** None, or `supabase.functions.invoke('get-meme-suggestions')` if logic allows for custom images (currently assumed not).
    *   **UI Feedback:** Proceeds to navigation.

6.  **User Action (Navigation):** `_processMeme()` navigates to `MemeDisplayScreen`.
    *   **Expected Screen:** `MemeDisplayScreen`.
    *   **Key Methods:** `Navigator.push` with `MemeData` (containing `localImageFile` for the custom image, entered text, `isCustomImage = true`).
    *   **State Changes:** `MemeDisplayScreen` initializes with `MemeData`.
    *   **Supabase Interactions:** None.
    *   **UI Feedback:** Transition to `MemeDisplayScreen`. Meme preview shown using the custom image and overlaid text.

---

**Step B.3: Meme Finalization & Sharing**

1.  **User Action:** User verifies meme preview on `MemeDisplayScreen`.
    *   **Expected Screen:** `MemeDisplayScreen`.
    *   **Key Methods:** `MemeDisplayScreen._buildMemePreview()`.
    *   **UI Feedback:** Custom image with text correctly displayed.

2.  **User Action:** User taps "Share".
    *   **Expected Screen:** `MemeDisplayScreen`.
    *   **Key Methods:** `MemeDisplayScreen._shareMeme()`. This involves:
        *   Capturing widget using `RepaintBoundary` (`_captureWidgetAsBytes()`).
        *   Saving the captured bytes to a temporary file (`getApplicationDocumentsDirectory`, `File.writeAsBytes`).
        *   Using `Share.shareXFiles()` (from `share_plus` package) with the path to the temporary file.
    *   **State Changes:** `_MemeDisplayScreenState._isSharing = true` during operation, then `false`.
    *   **Supabase Interactions:** None for sharing itself.
    *   **UI Feedback:** Loading indicator (e.g., on Share button or overlay). Native OS share dialog appears. `SnackBar` "Meme shared!" or error `SnackBar`.

---

**Step B.4: (Optional) Save & View in History**

1.  **User Action:** User taps "Save".
    *   **Expected Screen:** `MemeDisplayScreen`.
    *   **Key Methods:** `MemeDisplayScreen._saveMeme()`.
        *   Capture widget.
        *   Upload image bytes to Supabase Storage (path should indicate it's a custom meme, e.g., `user_id/custom_memes/timestamp.png`).
        *   Save metadata to Supabase Database (`memes` table: `user_id`, `image_url` from storage, text, `is_custom_image = true`, `template_id = null`).
    *   **State Changes:** `_MemeDisplayScreenState._isSaving = true`, then `false`.
    *   **Supabase Interactions:**
        *   `storage.uploadBinary` to `user_memes` bucket.
        *   `database.insert` into `memes` table.
    *   **UI Feedback:** Loading indicator. `SnackBar` "Meme saved successfully!" or error.

2.  **User Action:** User navigates to "History" tab.
    *   **Expected Screen:** `HistoryScreen`.
    *   **Key Methods:** `MainScreen._onItemTapped(1)`, `HistoryScreen._fetchMemeHistory(isInitialFetch: true)` (if not already loaded/or if refreshing).
    *   **State Changes:** `_allHistoryMemes` populated/updated.
    *   **Supabase Interactions:** `database.select` from `memes` table.
    *   **UI Feedback:** History list updates, showing the newly saved custom meme.

---

**Step B.5: Logout**

1.  **User Action:** User taps "Logout".
    *   **Expected Screen:** `MainScreen` -> `LoginScreen`.
    *   **Key Methods:** `MainScreen._performLogout()`, `Supabase.instance.client.auth.signOut()`.
    *   **State Changes:** `_MemeAppState._session` becomes null.
    *   **Supabase Interactions:** `auth.signOut()`.
    *   **UI Feedback:** Confirmation, loading, transition to `LoginScreen`.

---
---

## Scenario C: AI Suggestion Interaction Details

**Objective:** Verify the user interactions with AI-driven suggestions (tone, keywords, templates) on the `TextInputScreen` and ensure that selecting a suggestion correctly updates the meme creation context.

---

**Assumptions:**
*   User is on `TextInputScreen`.
*   User has already entered some top/bottom text.
*   The "Get Suggestions & Prepare" button's primary role, after fetching suggestions, is to display them. The navigation to `MemeDisplayScreen` happens via a separate "Preview Meme" or "Next" button (or similar, which might be the same button changing its label/function, or implicitly when `_processMeme` is called after selection). For this scenario, we focus on interactions *before* explicitly proceeding to `MemeDisplayScreen` *unless* a suggestion directly leads to it.

**Step C.1: Requesting and Displaying AI Suggestions**

1.  **User Action:** User has entered text (e.g., "When the coffee hits") and taps "Get Suggestions & Prepare".
    *   **Expected Screen:** `TextInputScreen`.
    *   **Key Methods:** `TextInputScreen._processMeme()` which calls `_getMemeSuggestions()`.
    *   **State Changes:**
        *   `_isLoadingSuggestions = true`.
        *   (On success from Edge Function) `_suggestionResults` populated with tone, keywords, and suggested `TemplateInfo` objects. `_showSuggestionsCard = true`. `_isLoadingSuggestions = false`.
        *   (On failure) `_suggestionError` set. `_showSuggestionsCard = true` (to display error within card) or false with a `SnackBar`. `_isLoadingSuggestions = false`.
    *   **Supabase Interactions:** `supabase.functions.invoke('get-meme-suggestions', body: {'text_input': ..., 'current_template_id': ...})`.
    *   **UI Feedback:** Loading indicator (e.g., overlay on suggestions card area or button changes to loading state). Then, the "AI Suggestions" card becomes visible.
        *   Tone displayed (e.g., "Humorous").
        *   Keywords displayed as tappable `ActionChip`s (e.g., "coffee", "morning", "energy").
        *   Suggested templates displayed in a horizontal list using `SuggestedTemplateItem` widget (thumbnails and names).

**Step C.2: Interacting with Keyword Suggestions**

1.  **User Action:** User taps a keyword `ActionChip` (e.g., "coffee").
    *   **Expected Screen:** `TextInputScreen` (Suggestions card remains visible).
    *   **Key Methods:** `ActionChip.onPressed` callback.
    *   **State Changes:** No direct state change that alters the selected template or text based *only* on tapping a keyword chip (as per current implementation plan which focuses on template selection from suggestions). This action is more for user feedback or future filtering.
    *   **Supabase Interactions:** None.
    *   **UI Feedback:** A `SnackBar` appears: "Tapped on keyword: coffee (Action placeholder)". (This matches the implemented `onKeywordChipTap`.)

**Step C.3: Interacting with Suggested Templates**

1.  **User Action:** User taps a `SuggestedTemplateItem` from the horizontal list in the AI Suggestions card.
    *   **Expected Screen:** `TextInputScreen`.
    *   **Key Methods:** `SuggestedTemplateItem.onTap` callback, which calls `_onSuggestedTemplateSelected(suggestedTemplate)`.
    *   **State Changes:**
        *   `_selectedTemplateId = suggestedTemplate.id`.
        *   `_selectedTemplateName = suggestedTemplate.name`.
        *   `_selectedTemplateImageUrl = suggestedTemplate.imageUrl`.
        *   `_customImageFile = null` (clears any custom image).
        *   `_showSuggestionsCard = false` (as per current logic, a selection hides the card).
        *   The main template preview area on `TextInputScreen` updates.
    *   **Supabase Interactions:** None.
    *   **UI Feedback:**
        *   The AI Suggestions card might hide (or update to show the selection).
        *   The main template image preview area (above the text input fields) updates to show the newly selected template.
        *   The text indicating the selected template name updates.
        *   The "Upload Image" button text might reset if it was showing a custom image filename.

**Step C.4: Proceeding to Meme Display after AI Template Selection**

1.  **User Action:** User (implicitly or explicitly) decides to proceed with the AI-suggested template now loaded into the main selection area. They might tap the "Get Suggestions & Prepare" button again (if its role changes to "Preview Meme" or "Next") or a dedicated "Preview Meme" button.
    *   **Expected Screen:** `TextInputScreen` then navigates to `MemeDisplayScreen`.
    *   **Key Methods:** `TextInputScreen._processMeme()`. This time, it sees `_selectedTemplateId` is populated (from the AI suggestion). It will *not* call `_getMemeSuggestions()` again if a template is already selected and no text has changed significantly to warrant new suggestions (this logic might need refinement). It prepares `MemeData`. `Navigator.push` to `MemeDisplayScreen`.
    *   **State Changes:** None in `TextInputScreen` after navigation. `MemeDisplayScreen` initializes with `MemeData` reflecting the AI-suggested template and existing text.
    *   **Supabase Interactions:** None.
    *   **UI Feedback:** Transition to `MemeDisplayScreen`. The preview shows the AI-selected template with the user's original text.

**Potential Issues/Areas for Refinement during Walkthrough:**
*   **Behavior of "Get Suggestions & Prepare" button:** What happens if the user taps it *again* after selecting an AI-suggested template? Does it re-fetch suggestions, or does it navigate to `MemeDisplayScreen`? The flow implies it should navigate. The button might need to change its label to "Preview Meme" or "Next" once a template (either manually chosen or AI-suggested) is set. (Current `_processMeme` logic: if a template is selected, it navigates; otherwise, it tries to get suggestions. This seems okay.)
*   **Clearing suggestions:** When should the `_suggestionResults` and `_showSuggestionsCard` be reset?
    *   Currently, selecting a suggested template hides the card (`_showSuggestionsCard = false`). This is good.
    *   If the user *manually* picks a different template (not from suggestions) or uploads a custom image *after* suggestions are shown, the card should also hide. (This is handled: `_selectTemplate`, `_pickCustomImage` set `_showSuggestionsCard = false`).
    *   If the user edits the text *after* suggestions are shown, should the current suggestions be hidden or marked as stale? (Currently, they remain visible. User needs to tap "Get Suggestions & Prepare" again to refresh). This is an acceptable UX.
*   **Custom Image with Suggestions:** The current flow for AI suggestions is primarily tied to text input for template-based memes. If a user uploads a custom image, the "Get Suggestions & Prepare" button should ideally not trigger template suggestions. (Current `_getMemeSuggestions` sends `current_template_id`. If custom image, this would be null. The Edge Function needs to handle this gracefully, perhaps returning no template suggestions or suggestions relevant to custom images if designed for it). The `_processMeme` method correctly prioritizes navigation if a custom image or template is already set.

---
---

## Scenario D: Key Error Handling Points

**Objective:** Verify that the application handles common error conditions gracefully, provides appropriate user feedback, and maintains stability across different functionalities.

---

**D.1: Authentication Errors**

1.  **Action:** Attempt login with invalid credentials on `LoginScreen`.
    *   **Screen/Method:** `LoginScreen._performLogin()`.
    *   **Supabase Interaction:** `auth.signInWithPassword()` fails.
    *   **Expected Exception:** `AuthException` (e.g., "Invalid login credentials").
    *   **UI Feedback:** `_isLoading = false`. `SnackBar` shown with the specific error message from `AuthException.message`. Login button becomes active again.
    *   **Stability:** App remains on `LoginScreen`, stable.

2.  **Action:** Attempt login with an unconfirmed email (if email confirmation is enabled and enforced).
    *   **Screen/Method:** `LoginScreen._performLogin()`.
    *   **Supabase Interaction:** `auth.signInWithPassword()` fails due to unconfirmed email.
    *   **Expected Exception:** `AuthException` (e.g., "Email not confirmed").
    *   **UI Feedback:** `_isLoading = false`. `SnackBar` shown with "Please confirm your email address." or similar.
    *   **Stability:** App remains on `LoginScreen`, stable.

3.  **Action:** Attempt sign-up on `SignUpScreen` with an email that already exists.
    *   **Screen/Method:** `SignUpScreen._performSignUp()`.
    *   **Supabase Interaction:** `auth.signUp()` fails.
    *   **Expected Exception:** `AuthException` (e.g., "User already registered", "Email rate limit exceeded").
    *   **UI Feedback:** `_isLoading = false`. `SnackBar` shown with the error message. Sign-up button becomes active.
    *   **Stability:** App remains on `SignUpScreen`, stable.

4.  **Action:** Attempt sign-up with a weak password (if Supabase has password policies).
    *   **Screen/Method:** `SignUpScreen._performSignUp()`.
    *   **Supabase Interaction:** `auth.signUp()` fails.
    *   **Expected Exception:** `AuthException` (e.g., "Password should be at least 6 characters").
    *   **UI Feedback:** `_isLoading = false`. `SnackBar` shown with the error message.
    *   **Stability:** App remains on `SignUpScreen`, stable.

---

**D.2: Data Fetching Errors (Templates & History)**

1.  **Action:** Initial load of templates fails on `TextInputScreen` (e.g., network error, Supabase RLS issue).
    *   **Screen/Method:** `TextInputScreen._fetchTemplates(isInitialFetch: true)` (called from `_selectTemplate`).
    *   **Supabase Interaction:** `supabase.from('templates').select()` fails.
    *   **Expected Exception:** `PostgrestException`.
    *   **UI Feedback:**
        *   Inside template browser modal: `_isLoadingTemplates = false`, `_fetchTemplatesError` is set.
        *   The modal shows an error message (e.g., "Could not load templates. Tap to retry.") with a retry button.
        *   Tapping retry calls `_fetchTemplates(isInitialFetch: true)` again.
    *   **Stability:** Modal remains open or can be dismissed. Main `TextInputScreen` stable.

2.  **Action:** "Load more" for templates fails in template browser.
    *   **Screen/Method:** `TextInputScreen._fetchTemplates(isInitialFetch: false)`.
    *   **Supabase Interaction:** `supabase.from('templates').select().range(...)` fails.
    *   **Expected Exception:** `PostgrestException`.
    *   **UI Feedback:**
        *   `_isLoadingMoreTemplates = false`, `_fetchTemplatesError` is set.
        *   A `SnackBar` is shown: "Failed to load more templates: [error message]" with a RETRY action.
        *   Existing templates remain visible. The "load more" indicator at the bottom disappears or shows an error indicator that can be tapped to retry.
    *   **Stability:** Template browser modal remains open and interactive.

3.  **Action:** Initial load of meme history fails on `HistoryScreen`.
    *   **Screen/Method:** `HistoryScreen._fetchMemeHistory(isInitialFetch: true)` (called from `initState`).
    *   **Supabase Interaction:** `supabase.from('memes').select()` fails.
    *   **Expected Exception:** `PostgrestException`.
    *   **UI Feedback:** `_isLoadingInitialHistory = false`, `_fetchHistoryError` is set. The `build()` method displays the full-screen error UI with "Oops! Could not load your history. Error: [message]" and a "Retry" button.
    *   **Stability:** App remains on `HistoryScreen`, stable. Retry button functions.

4.  **Action:** "Load more" for meme history fails on `HistoryScreen`.
    *   **Screen/Method:** `HistoryScreen._fetchMemeHistory(isInitialFetch: false)`.
    *   **Supabase Interaction:** `supabase.from('memes').select().range(...)` fails.
    *   **Expected Exception:** `PostgrestException`.
    *   **UI Feedback:** `_isLoadingMoreHistory = false`, `_fetchHistoryError` is set. A `SnackBar` is shown: "Failed to load more: [error message]" with a RETRY action. Existing history items remain visible. The "load more" indicator at the bottom of the `GridView` disappears.
    *   **Stability:** App remains on `HistoryScreen`, stable.

---

**D.3: Meme Saving Errors (`MemeDisplayScreen`)**

1.  **Action:** Image upload to Supabase Storage fails during `_saveMeme()`.
    *   **Screen/Method:** `MemeDisplayScreen._saveMeme()` -> `supabase.storage.from('user_memes').uploadBinary()`.
    *   **Supabase Interaction:** `storage.uploadBinary()` fails (e.g., RLS policy violation, network issue, bucket not found).
    *   **Expected Exception:** `StorageException`.
    *   **UI Feedback:** `_isSaving = false`. `SnackBar` shown with "Failed to save meme: Error uploading image. [StorageException message]". Save button becomes active.
    *   **Stability:** App remains on `MemeDisplayScreen`, stable. User can retry saving.

2.  **Action:** Metadata insert into Supabase Database fails during `_saveMeme()` (after successful image upload).
    *   **Screen/Method:** `MemeDisplayScreen._saveMeme()` -> `supabase.from('memes').insert()`.
    *   **Supabase Interaction:** `database.insert()` fails (e.g., RLS, policy violation, network issue).
    *   **Expected Exception:** `PostgrestException`.
    *   **UI Feedback:** `_isSaving = false`. `SnackBar` shown with "Failed to save meme: Error saving metadata. [PostgrestException message]".
        *   *Consideration:* Does this also attempt to delete the already uploaded image from storage to prevent orphans? (Currently, no explicit cleanup logic for this case).
    *   **Stability:** App remains on `MemeDisplayScreen`, stable.

---

**D.4: Edge Function Call Errors (`get-meme-suggestions`)**

1.  **Action:** Calling `get-meme-suggestions` Edge Function fails from `TextInputScreen._getMemeSuggestions()`.
    *   **Screen/Method:** `TextInputScreen._getMGMESuggestions()` -> `supabase.functions.invoke()`.
    *   **Supabase Interaction:** `functions.invoke()` fails (e.g., function error, network issue, timeout).
    *   **Expected Exception:** `FunctionsException` or general `Exception` if wrapped.
    *   **UI Feedback:** `_isLoadingSuggestions = false`. `_suggestionError` is set with a user-friendly message (e.g., "Could not fetch suggestions: [error message]"). The AI Suggestions card might display this error, or a `SnackBar` could be shown. "Get Suggestions & Prepare" button becomes active.
    *   **Stability:** App remains on `TextInputScreen`, stable. User can retry or proceed without suggestions.

---

**General Error Handling Observations:**
*   Loading flags (`_isLoading...`, `_isSaving`, etc.) are generally reset in `finally` blocks or after catching errors, which is good for UI responsiveness.
*   `SnackBar`s are the primary mechanism for non-critical/partial errors (e.g., "load more" failure, save failure after which user can retry).
*   Full-screen error UIs (with retry buttons) are used for critical initial load failures (e.g., `HistoryScreen` initial load).
*   Error messages from Supabase exceptions (`AuthException`, `PostgrestException`, etc.) are often directly included in user feedback. While informative for debugging, they might need further sanitization or mapping to more user-friendly strings for a production app, but for this conceptual test, it's acceptable to see them.

---
---

## Summary of Findings

The conceptual end-to-end tests covered new user registration, login, meme creation with both templates and custom images, AI suggestion interactions, meme saving, sharing, history viewing, logout, and various error handling scenarios.

**Key Positive Findings:**
*   **Core User Flows:** The primary user journeys for creating and managing memes are logically sound. State transitions between screens and within stateful widgets appear to correctly handle user inputs and data flow.
*   **Authentication:** Sign-up, login, and logout processes, including basic error handling for existing users or invalid credentials, align with expectations.
*   **Data Handling:** Fetching templates and user history, including pagination and pull-to-refresh, has been well-defined. Saving memes involves appropriate Supabase interactions for storage and database.
*   **Error Handling:**
    *   Critical errors (like initial data load failures) generally present clear error UIs with retry options.
    *   Non-critical errors (like "load more" failures or individual save/suggestion issues) primarily use `SnackBar`s for feedback, often with retry actions, allowing the user to continue interacting with other parts of the app.
    *   Loading states are generally well-managed, providing feedback to the user during operations.

**Minor Refinements Implemented During Review Process:**
*   **Enhanced Error Feedback:** The "load more" functionality for templates in `text_input_screen.dart` was updated to include a "RETRY" action in its error `SnackBar`, ensuring consistency with similar error handling in `HistoryScreen`.
*   **Improved Code Clarity:** Introduced `static const double _scrollOffsetThreshold` in `HistoryScreen` and `static const double _templateScrollOffsetThreshold` in `TextInputScreen` to replace magic numbers used for triggering paginated content loading, enhancing code readability and maintainability.

**Areas for Attention or Future Refinement (as noted in scenario walkthroughs):**
*   **AI Suggestions UI Flow (`Scenario C`):**
    *   The role of the "Get Suggestions & Prepare" button could be clarified or changed (e.g., to "Preview Meme") after suggestions have been fetched or a suggested template has been applied, to make the next step more intuitive.
    *   The interaction between custom image uploads and the AI suggestion feature needs clear definition (currently, suggestions are primarily template-focused).
*   **Meme Saving (`Scenario D.3`):**
    *   Consider implementing a cleanup mechanism for orphaned images in Supabase Storage if the corresponding database metadata fails to save. This is a common resiliency pattern.
*   **Error Message Presentation (`Scenario D`):**
    *   While direct Supabase error messages are useful for development, for a production release, these should be sanitized or mapped to more generic, user-friendly messages to avoid exposing technical details.
*   **Navigation from Empty States:** Placeholder TODOs for navigation (e.g., "Create a Meme" button in empty `HistoryScreen` or error states) should be implemented with actual navigation logic.

Overall, the application's design demonstrates a solid foundation for the intended user experience.
---

## Overall Conclusion

Based on the detailed conceptual walkthrough of the defined end-to-end scenarios, the M3M3s application's architecture and user flow design appear robust and well-considered for the implemented features. The application handles primary user journeys logically, manages state effectively, and incorporates necessary feedback mechanisms for common error conditions.

While a few minor areas for future refinement and clarification have been noted (particularly around advanced AI suggestion interactions, specific error recovery details like orphaned file cleanup, and production-level error message presentation), the core functionalities are conceptually sound. The application seems ready for more detailed implementation of TODOs (like navigation from empty states) and progression to live testing of these flows.
---
