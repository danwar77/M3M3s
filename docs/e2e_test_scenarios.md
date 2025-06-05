# End-to-End Conceptual Test: Key User Scenarios

## Date: 2025-05-31

This document outlines the key user scenarios that will be conceptually tested to ensure the overall application flow, data integrity, and user experience of the M3M3s application are coherent and functional.

### Core Scenarios:

**Scenario A: New User Journey (Template Meme)**
1.  **App Start & Sign-Up:**
    *   User starts the app for the first time.
    *   User navigates from `LoginScreen` to `SignUpScreen`.
    *   User successfully signs up (including handling of email confirmation messages, if applicable).
2.  **Login:**
    *   User logs in via `LoginScreen` with newly created credentials.
3.  **Meme Creation (Template):**
    *   User navigates from `CreateScreen` (Welcome/Dashboard) to `TextInputScreen`.
    *   User selects a predefined template from the paginated template browser.
    *   User enters top and bottom text for the meme.
    *   User initiates meme processing (e.g., taps "Get Suggestions & Prepare").
    *   (Optional) User views AI suggestions but proceeds with their chosen template and text.
    *   User is navigated to `MemeDisplayScreen`.
4.  **Meme Finalization & Saving:**
    *   User verifies the meme preview on `MemeDisplayScreen`.
    *   (Optional) User makes minor edits to text/style.
    *   User taps "Save". Meme is captured, image uploaded to Supabase Storage, metadata saved to Supabase Database.
5.  **View in History:**
    *   User navigates to the "History" tab (`HistoryScreen`).
    *   User verifies the newly saved meme is present in the paginated history list.
6.  **Logout:**
    *   User taps the "Logout" button from `MainScreen`.
    *   User is navigated back to `LoginScreen`.

**Scenario B: Existing User Journey (Custom Image Meme & Share)**
1.  **App Start & Login:**
    *   User starts the app.
    *   User successfully logs in via `LoginScreen` with existing credentials.
2.  **Meme Creation (Custom Image):**
    *   User navigates to `TextInputScreen`.
    *   User taps "Upload Image" and selects an image from their device gallery/camera.
    *   The custom image preview updates on `TextInputScreen`.
    *   User enters top and bottom text.
    *   User initiates meme processing.
    *   User is navigated to `MemeDisplayScreen`.
3.  **Meme Finalization & Sharing:**
    *   User verifies the meme preview on `MemeDisplayScreen`.
    *   User taps "Share". The meme is captured, and the native share dialog appears.
4.  **(Optional) Save & View in History:**
    *   User taps "Save".
    *   User navigates to `HistoryScreen` and verifies the new meme (with custom image base) is present.
5.  **Logout.**

### Specific Feature Interaction Scenarios:

**Scenario C: AI Suggestion Interaction Details**
1.  **On `TextInputScreen` (after entering text and tapping "Get Suggestions & Prepare"):**
    *   Verify clear display of analyzed tone and keywords (as `ActionChip`s).
    *   Verify display of suggested templates (using `SuggestedTemplateItem`).
    *   User taps a keyword `ActionChip` (verify placeholder `SnackBar` appears).
    *   User taps a `SuggestedTemplateItem`.
        *   Verify the main template selection area (`_selectedTemplateId`, `_selectedTemplateName`, `_selectedTemplateImageUrl`) updates.
        *   Verify the AI suggestions card is hidden or updated.
        *   Verify any custom image selection is cleared.
    *   User proceeds to `MemeDisplayScreen` using the AI-suggested template.

### Error Handling Scenarios:

**Scenario D: Key Error Handling Points**
1.  **Authentication:**
    *   **Login:** Attempt login with invalid credentials; attempt login with an unconfirmed email (if applicable).
    *   **SignUp:** Attempt sign-up with an email that already exists; attempt sign-up with a weak password.
2.  **Data Fetching (Templates & History):**
    *   Simulate initial load failure (verify error UI and "Retry" button).
    *   Simulate "load more" failure during infinite scroll (verify `SnackBar` feedback and retry if implemented).
3.  **Meme Saving (`MemeDisplayScreen`):**
    *   Simulate failure during image upload to Supabase Storage.
    *   Simulate failure during metadata insert into Supabase Database.
4.  **Edge Function Call (`get-meme-suggestions`):**
    *   Simulate an error response from the Edge Function.
*   *For all error scenarios, verify that appropriate user-friendly feedback is provided, the UI remains stable, and retry mechanisms function as expected.*

These scenarios aim to cover the primary functionalities and critical paths of the application.

