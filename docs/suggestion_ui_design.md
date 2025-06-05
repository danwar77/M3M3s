# Enhanced UI Design for AI Suggestions in TextInputScreen

## Date: 2024-03-11

## 1. Overview

This document outlines an enhanced UI design for presenting the results (analyzed text and suggested templates) returned by the `get-meme-suggestions` Supabase Edge Function. These suggestions will be displayed within the `TextInputScreen` to help users refine their meme creation process. The goal is to make this information clear, digestible, and actionable.

## 2. Triggering and Visibility

*   The suggestions UI will become visible after the `get-meme-suggestions` Edge Function successfully returns data and `_suggestionResults` in `_TextInputScreenState` is populated.
*   It will be hidden or cleared if the user selects a new template manually, uploads a new custom image, or modifies the input text and re-requests suggestions.
*   It will be displayed only when `_isProcessing` is `false`.

## 3. Main Suggestions Display Area

The suggestions will be displayed within a dedicated `Card` widget below the "Get Suggestions & Prepare" button (or its equivalent) and above the text input fields, or in a clearly demarcated section. This card will provide a visual grouping for all AI-driven feedback.

**Structure of the Suggestions `Card`:**

```
Card
  elevation: 2.0
  margin: EdgeInsets.symmetric(vertical: 16.0)
  child: Padding
    padding: EdgeInsets.all(16.0)
    child: Column (crossAxisAlignment: CrossAxisAlignment.start)
      - Header Text
      - Analyzed Text Details Section
      - (Optional Divider)
      - Suggested Templates Section (if any)
```

### 3.1. Header

*   **Content:** A `Text` widget with a title like "AI Suggestions & Analysis" or "Content Insights".
*   **Styling:** Use `Theme.of(context).textTheme.titleMedium` or `titleLarge`, possibly with a primary or secondary color from the theme.
*   A `Divider` can be placed below the header for visual separation.

### 3.2. Analyzed Text Details Section

This section will display the NLP results from `_suggestionResults['analyzedText']`.

*   **Layout:** A `Column` of `Row`s or `ListTile`s for each piece of analyzed information.
*   **Detected Tone:**
    *   **Display:** A `Row` containing:
        *   An `Icon` (e.g., `Icons.sentiment_satisfied_alt_outlined` for positive, `Icons.mood_bad_outlined` for negative, `Icons.bubble_chart_outlined` for general tone). The icon could change based on the `toneValue`.
        *   A `Text` widget: `Text("Detected Tone: ${toneValue}")`.
    *   `toneValue` is extracted from `_suggestionResults['analyzedText']['tone']`.
*   **Keywords:**
    *   **Display:**
        *   A `Text` widget: `Text("Keywords:", style: theme.textTheme.labelLarge)`.
        *   Followed by a `Wrap` widget. Each keyword from `_suggestionResults['analyzedText']['keywords']` will be rendered as a `Chip` widget.
        *   `Chip(label: Text(keyword), padding: EdgeInsets.symmetric(horizontal: 4, vertical: 0))`
    *   **Future Interaction (Out of Scope for Initial Implementation):** Tapping a keyword `Chip` could potentially:
        *   Refine the template list displayed in the template browser.
        *   Add the keyword as a tag if the user decides to save the meme with tags.
*   **Detected Language (Optional Display):**
    *   If useful to display: A `Row` with `Icon(Icons.language)` and `Text("Language: ${languageValue}")`.
    *   `languageValue` from `_suggestionResults['analyzedText']['language']`.

### 3.3. Suggested Templates Section (Conditional)

This section is displayed only if `_suggestionResults['suggestedTemplates']` exists, is not null, and is not empty.

*   **Layout:**
    *   A `Divider` can be used to separate this from the "Analyzed Text Details" if both are present.
    *   A `Text` widget: `Text("Suggested Templates:", style: theme.textTheme.labelLarge)`.
*   **Display Method for Suggested Templates:**
    *   If there are 1-3 suggestions, a `Column` of `SuggestedTemplateItem` widgets (or `ListTile`s) can be used.
    *   If more suggestions are expected (e.g., > 3-5), a horizontally scrollable `ListView.builder` (`scrollDirection: Axis.horizontal`) with a fixed height (e.g., 150-200 pixels) would be more appropriate to avoid making the suggestions card too long. Each item in this list would be a `SuggestedTemplateItem`.
*   **`SuggestedTemplateItem` Widget (Conceptual - to be implemented if this design is chosen):**
    *   **Content:**
        *   **Thumbnail:** An `Image.network` widget displaying `suggestedTemplate['thumbnailUrl']` (if provided by the Edge Function, otherwise `suggestedTemplate['imageUrl']`). Include robust `loadingBuilder` and `errorBuilder`. A fixed size (e.g., width: 100-120, height: corresponding aspect ratio) should be used.
        *   **Name:** `Text(suggestedTemplate['name'])` below the thumbnail.
        *   **Match Score (Optional):** If `suggestedTemplate['matchScore']` is provided, display it subtly (e.g., `Text("Relevance: ${(score * 100).toStringAsFixed(0)}%")`).
    *   **Interactivity:** The entire `SuggestedTemplateItem` will be tappable.
        *   **Action:** When tapped, it will:
            1.  Update `_TextInputScreenState` by setting `_selectedTemplateId`, `_selectedTemplateName`, and `_selectedTemplateImageUrl` with the details of the tapped suggested template.
            2.  Clear `_customImageFile`.
            3.  Optionally, clear or hide the `_suggestionResults` display itself, as a selection has been made.
            4.  Show a `SnackBar` confirming the selection: `"${templateName}" selected from suggestions.`.
*   **No Specific Template Suggestions:** If `_suggestionResults['analyzedText']` is present but `_suggestionResults['suggestedTemplates']` is empty or not provided, a message like `Text("No specific template suggestions for this text, but you can still browse all templates!")` can be shown.

## 4. Styling and General UX

*   **Theme Consistency:** All text, icons, and components will utilize `Theme.of(context)` and `ColorScheme.of(context)` for consistent styling.
*   **Readability:** Ensure sufficient padding within the `Card` and between sections. Use appropriate text styles for hierarchy.
*   **Clarity:** The suggestions card should be clearly distinguishable as AI-generated feedback.
*   **Actionability:** Suggested templates should be easily selectable.
*   **Responsiveness:** If a horizontal `ListView` is used for suggested templates, ensure it looks good on various screen widths. `Wrap` for keywords is inherently responsive.

## 5. Interaction Summary for Suggestions

1.  User inputs text and taps "Get Suggestions & Prepare".
2.  `_isProcessing` becomes true, UI shows loading.
3.  Edge Function `get-meme-suggestions` is called.
4.  On success:
    *   `_isProcessing` becomes false.
    *   `_suggestionResults` is populated.
    *   The `TextInputScreen` rebuilds, and the Suggestions `Card` is displayed with tone, keywords, and suggested templates.
5.  User views suggestions.
6.  User can tap on a `SuggestedTemplateItem`:
    *   This updates the main selected template preview area at the top of `TextInputScreen` with the chosen suggested template.
    *   The `_suggestionResults` card might be cleared or updated to indicate the selection.
7.  User can ignore suggestions and still use the main "Choose Template" or "Upload Custom" buttons. Selecting a template/image through these main buttons should clear `_suggestionResults`.

This enhanced UI design aims to make the AI-powered suggestions more integrated into the user's workflow, providing valuable insights and actionable shortcuts for template selection.
```
