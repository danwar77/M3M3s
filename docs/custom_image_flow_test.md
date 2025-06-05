# Conceptual Test: Custom Image Upload Flow

## Date: 2024-03-11

## Objective:
To conceptually test the user flow for selecting/uploading a custom image in `TextInputScreen`, its passage to `MemeDisplayScreen`, and how this data is handled for display and subsequent saving operations, ensuring the `localImageFile` is prioritized and correctly identified as a custom image.

## Test Scenario Steps & Verifications:

1.  **User on `TextInputScreen` (Initial State):**
    *   **Action:** User launches the app and navigates to `TextInputScreen` (or it's the initial screen in the "Create" tab).
    *   **Expected UI State:**
        *   `_customImageFile` is `null`.
        *   `_selectedTemplateId`, `_selectedTemplateName`, `_selectedTemplateImageUrl` are all `null`.
        *   The preview card (`_buildPreviewCard()`) displays the placeholder: "No image selected. Tap card or use buttons below."
        *   The "Get Suggestions & Prepare" button is **disabled** because `canProcessMeme` (`!_isProcessing && (_selectedTemplateImageUrl != null || _customImageFile != null)`) evaluates to `false`.
    *   **Verification:** **PASS.** The initial state correctly reflects no image/template selection and the action button is disabled.

2.  **User Selects a Custom Image:**
    *   **Action:** User taps the "Upload Custom" `TextButton.icon`.
    *   **Expected Flow:**
        *   `_showImageSourceSelection()` is called.
        *   A modal bottom sheet appears, offering "Photo Library" and "Camera" options.
        *   User taps "Photo Library".
        *   `_pickImage(ImageSource.gallery)` is called.
        *   The `ImagePicker().pickImage()` dialog opens. User selects an image (e.g., `my_cat.png`).
        *   `pickedFile` (an `XFile`) is returned.
        *   In `_pickImage()`, `setState` is called:
            *   `_customImageFile` is set to `File('path/to/my_cat.png')`.
            *   `_selectedTemplateId`, `_selectedTemplateName`, `_selectedTemplateImageUrl` are all set to `null` (clearing any prior template selection).
            *   `_suggestionResults` is set to `null`.
        *   A `SnackBar` "Custom image selected!" is displayed.
        *   The `TextInputScreen` UI rebuilds:
            *   `_buildPreviewCard()` now renders the custom image:
                *   `Image.file(_customImageFile!)` displays `my_cat.png`.
                *   An 'X' button (`IconButton`) is shown on the preview to remove the custom image.
                *   Text like "Custom Image" and "Tap card to change or remove" is displayed.
            *   The "Get Suggestions & Prepare" button (`canProcessMeme`) becomes **enabled** because `_customImageFile` is now non-null.
    *   **Verification:** **PASS.** The state update logic correctly prioritizes the custom image, clears any template selection, and the UI reflects these changes. The action button is enabled.

3.  **User Enters Text:**
    *   **Action:** User types "My Cat" into `_topTextController` and "Is Awesome" into `_bottomTextController`.
    *   **Expected State:** The respective text controllers hold these values.
    *   **Verification:** **PASS.** Standard `TextEditingController` behavior.

4.  **User Taps "Get Suggestions & Prepare":**
    *   **Action:** User taps the now-enabled "Get Suggestions & Prepare" button.
    *   **Expected Flow (`_processMeme()` is called):**
        *   Form validation passes (assuming text meets criteria).
        *   The initial check `if (_customImageFile == null && (_selectedTemplateId == null || _selectedTemplateImageUrl == null))` passes because `_customImageFile` is not `null`.
        *   `_isProcessing` is set to `true`. UI updates (button shows loading indicator).
        *   The `get-meme-suggestions` Edge Function is called with appropriate text (e.g., "My Cat").
        *   Suggestions are received (or not, doesn't block flow), `_suggestionResults` is updated, and a relevant `SnackBar` is shown.
        *   `_isProcessing` is set back to `false`.
        *   **`MemeData` Instantiation:**
            *   The `if (_customImageFile != null)` condition is `true`.
            *   `memeDataForDisplay` is created with:
                *   `topText`: "My Cat"
                *   `bottomText`: "Is Awesome"
                *   `localImageFile`: The `File` object for `my_cat.png` (from `_customImageFile`).
                *   `imageUrl`: `null`.
                *   `templateId`: `null`.
        *   **Navigation:** `Navigator.push()` is called, navigating to `MemeDisplayScreen` with this `memeDataForDisplay`.
    *   **Verification:** **PASS.** `MemeData` is correctly populated, prioritizing `localImageFile` and ensuring `imageUrl` and `templateId` are `null` for a custom image flow.

5.  **User on `MemeDisplayScreen`:**
    *   **Action:** `MemeDisplayScreen` is pushed onto the navigation stack with `initialMemeData`.
    *   **Expected State & UI (`MemeDisplayScreen`):**
        *   `widget.initialMemeData.localImageFile` is the `File` object for `my_cat.png`.
        *   `widget.initialMemeData.imageUrl` is `null`.
        *   `widget.initialMemeData.templateId` is `null`.
        *   In `_MemeDisplayScreenState.initState()`:
            *   `_topTextController` is initialized with "My Cat".
            *   `_bottomTextController` is initialized with "Is Awesome".
        *   In `_MemeDisplayScreenState._buildMemePreview()`:
            *   The condition `if (widget.initialMemeData.localImageFile != null)` is `true`.
            *   `imageWidget` becomes `Image.file(widget.initialMemeData.localImageFile!, ...)`, displaying `my_cat.png`.
            *   The entered text ("MY CAT", "IS AWESOME") is overlaid.
    *   **Verification:** **PASS.** `MemeDisplayScreen` correctly receives and uses the `localImageFile` from `MemeData` for display.

6.  **User Saves Meme on `MemeDisplayScreen`:**
    *   **Action:** User taps the "Save" button. `_saveMeme()` is called.
    *   **Expected Flow (`_saveMeme()`):**
        *   The displayed meme (with `my_cat.png` as base) is captured as `imageBytes`.
        *   These bytes are uploaded to Supabase Storage, resulting in `uploadedImageUrl`.
        *   The metadata prepared for insertion into the `memes` table will be:
            *   `user_id`: Current authenticated user's ID.
            *   `image_url`: The `uploadedImageUrl` (URL of the *final rendered meme* in storage).
            *   `text_input`: `{'top': "My Cat", 'bottom': "Is Awesome"}`.
            *   `template_id`: `widget.initialMemeData.templateId` (which is `null`). This will be removed from the insert map by the `if (memeDataToInsert['template_id'] == null) memeDataToInsert.remove('template_id');` logic.
            *   `is_custom_image`: Determined by `widget.initialMemeData.localImageFile != null || (widget.initialMemeData.imageUrl != null && widget.initialMemeData.templateId == null)`.
                *   Since `widget.initialMemeData.localImageFile != null` is `true`, `is_custom_image` correctly evaluates to `true`.
        *   The record saved to the database will correctly reflect that it's a custom image without a base template ID.
    *   **Verification:** **PASS.** The save logic correctly identifies the meme as originating from a custom image because `initialMemeData.localImageFile` was provided to `MemeDisplayScreen`.

## Conclusion:

The conceptual walkthrough of the custom image upload flow, from selection in `TextInputScreen` to display and saving in `MemeDisplayScreen`, indicates that the planned logic and data flow are **sound**.
*   `TextInputScreen` correctly handles the selection of a custom image, updates its internal state to prioritize this custom image (clearing any template selection), and previews the local file.
*   When proceeding to meme generation/preparation, `TextInputScreen` correctly populates `MemeData` by setting `localImageFile` and ensuring `imageUrl` (for template) and `templateId` are `null`.
*   `MemeDisplayScreen` is correctly set up to receive `MemeData` and prioritize `localImageFile` for display if it's present.
*   The saving mechanism in `MemeDisplayScreen` accurately determines the `is_custom_image` flag as `true` when the meme originates from a `localImageFile`.

The flow should function as intended, allowing users to use their own images for meme creation.

