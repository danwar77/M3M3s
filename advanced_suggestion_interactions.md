# Conceptual Interactions with Advanced AI Suggestions

This document outlines potential future interactions with the analyzed text suggestions (tone and keywords) provided by the `get-meme-suggestions` Edge Function in `TextInputScreen`. These interactions aim to make the AI-driven suggestions more deeply integrated into the user's workflow, providing more powerful and intuitive ways to create memes.

## 1. Detected Tone

*   **Current Display:** Informational text (e.g., "Detected Tone: humorous") within the suggestions card.
*   **Potential Future Interactions:**
    *   **Informational Tooltip/Dialog:** Tapping the "Detected Tone" text or an associated info icon could display a tooltip or a small dialog explaining:
        *   A brief definition of the detected tone in the context of memes.
        *   How this tone might have influenced the template suggestions (if applicable).
        *   Example: "Humorous: Suggests templates often used for jokes or light-hearted content."
    *   **Tone-based Template Filtering (Advanced):**
        *   If templates in the Supabase database are tagged with associated tones (e.g., `tags: ['funny', 'serious', 'animal']` could implicitly or explicitly include tone).
        *   Tapping the detected tone could act as a quick filter suggestion for the main template browser (the modal bottom sheet). For instance, it could pre-fill a search query or select a "tone" filter category if the browser supports it.
    *   **Tone Adjustment (Very Advanced / Requires Backend Logic):**
        *   Allow the user to manually override or adjust the detected tone via a dropdown or a set of choices.
        *   This adjusted tone could then be used to:
            *   Re-trigger a call to the `get-meme-suggestions` Edge Function with the new tone as an additional parameter to refine template suggestions.
            *   Influence parameters for AI image generation if that feature is implemented (e.g., adding "humorous style" to an image prompt).
            *   Be saved as metadata with the meme if the user finds the AI's tone assessment inaccurate but wants to record their own interpretation.

## 2. Keywords

*   **Current Display:** Displayed as interactive `ActionChip` widgets within the suggestions card. Tapping a chip currently shows a placeholder `SnackBar`.
*   **Potential Future Interactions (when `onPressed` is fully implemented):**
    *   **Filter Template Browser (Single Keyword):**
        *   Tapping a keyword chip could immediately apply that keyword as a filter to the main template browser. This might involve:
            *   Closing the suggestions card.
            *   Opening the template browser (`_selectTemplate()`) and passing the tapped keyword as an initial filter/search query. The `_fetchTemplates()` method would need to be adapted to accept such a query.
    *   **Add to Temporary Filter List (Multiple Keywords):**
        *   Tapping a keyword chip could add/remove it from a temporary list of "active keyword filters" displayed within the `TextInputScreen` (perhaps near the suggestions card or template preview).
        *   A button like "Apply Keyword Filters to Templates" would then open the template browser pre-filtered with all selected keywords.
    *   **Add as Meme Tag:**
        *   Tapping a keyword chip (perhaps with a different interaction, like a long-press or a dedicated "Add as Tag" icon on the chip) could add it to a list of user-defined tags for the current meme being created.
        *   These tags would then be passed in `MemeData` and saved with the meme in the `memes` table, allowing for better organization and searching of saved memes.
    *   **Refine AI Suggestions:**
        *   Tapping one or more keywords could enable a "Refine Suggestions with Keywords" button.
        *   Pressing this button would trigger a new call to the `get-meme-suggestions` Edge Function, passing the selected keywords as additional input parameters to get more targeted template suggestions.
    *   **Copy Keyword:**
        *   A long-press on a keyword chip could show a context menu with an option to "Copy keyword", allowing the user to paste it elsewhere.
    *   **Visual Feedback for Selected Keywords:** If keywords are used for filtering or tagging, their `Chip` appearance could change (e.g., different background color, checkmark icon) to indicate they are "active" or "selected".

## Implementation Notes for Future Development:

*   **State Management:** Implementing these interactive features will require managing additional state within `_TextInputScreenState`. This might include:
    *   A list of currently active keyword filters.
    *   A list of tags chosen for the current meme.
    *   The user-adjusted tone, if that feature is implemented.
*   **UI Changes:** The UI of `TextInputScreen` would need to be updated to:
    *   Display active keyword filters or selected meme tags.
    *   Include new buttons like "Apply Keyword Filters" or "Refine Suggestions".
*   **Backend/Edge Function Support:**
    *   For tone-based or keyword-refined template suggestions, the `get-meme-suggestions` Edge Function would need to be updated to accept these new parameters and use them in its logic (e.g., in database queries against the `templates` table).
    *   The `templates` table in Supabase might need more detailed tagging or a dedicated `tone` field if direct tone-based filtering is desired.
*   **Template Browser Enhancement:** The template browser (modal bottom sheet) would need to be enhanced to accept and apply filters passed from `TextInputScreen`.

These conceptual interactions aim to make the AI-driven suggestions a more dynamic and integral part of the meme creation process, offering users powerful tools to quickly find relevant templates or refine their creative direction.
```
