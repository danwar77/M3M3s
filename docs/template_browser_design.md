# Template Browser UI Design

This document outlines the UI design and interaction flow for the template browser feature in the M3M3s application. The browser will allow users to select a predefined meme template to use as a base for their creation.

## 1. Triggering Mechanism

*   **Source:** The template browser will be initiated from the `TextInputScreen`.
*   **Action:** A user will tap a button, likely labeled "Choose Template" or "Select From Templates".
*   **Method:** This tap action will trigger the `_selectTemplate()` method within `_TextInputScreenState`.
*   **UI Pattern:** The `_selectTemplate()` method will utilize `showModalBottomSheet()` to present the template browser to the user.

## 2. Modal Bottom Sheet Structure

The modal bottom sheet will provide a dynamic and scrollable interface for template selection.

*   **Root Widget:** A `DraggableScrollableSheet` will be used within the `showModalBottomSheet`. This allows the sheet to:
    *   Be initially shown at a partial height (e.g., 60% of screen height).
    *   Be dragged by the user to expand to a larger portion of the screen (e.g., up to 90%).
    *   Contain internally scrollable content if the list of templates is long.
*   **Sheet Content Layout:** The content within the `DraggableScrollableSheet` will be structured as follows:
    *   **Header Area (Optional but Recommended):**
        *   A small, centered drag handle indicator at the top.
        *   A clear title, such as "Select a Template".
        *   Possibly a close button (`IconButton` with `Icons.close`) on one side, although users can typically dismiss the sheet by dragging it down or tapping the scrim.
    *   **Filtering/Sorting Controls (Future Enhancement - Optional for initial version):**
        *   A small section for search bar, category dropdown, or sort options could be included here if desired for advanced browsing. For the initial version, this might be omitted for simplicity.
    *   **Main Content Area (Dynamic):** This area will display content based on the state of template data fetching:
        *   **Loading State:**
            *   A centered `CircularProgressIndicator`.
            *   A brief message like "Loading templates..." below the indicator.
        *   **Error State:**
            *   An icon (e.g., `Icons.error_outline`).
            *   A user-friendly error message (e.g., "Failed to load templates. Please check your connection and try again.").
            *   A "Retry" button to re-attempt fetching the templates.
        *   **Empty State:**
            *   An icon (e.g., `Icons.collections_bookmark_outlined` or `Icons.image_search`).
            *   A message like "No templates available at the moment." or "Looks like there are no templates here yet."
            *   Optionally, a "Refresh" button if new templates might be added frequently.
        *   **Data State (Templates Display):**
            *   A `GridView.builder` will be the primary component for displaying the templates.
                *   **Grid Configuration:**
                    *   Responsive `crossAxisCount` (e.g., 2 columns on smaller phones, 3-4 on larger phones/tablets).
                    *   Appropriate `crossAxisSpacing` and `mainAxisSpacing`.
                    *   `childAspectRatio` to ensure template items are displayed well (e.g., slightly taller than wide if names are below images).
                *   **Item Rendering:** Each cell in the grid will be an instance of a dedicated `TemplateListItem` widget (detailed in Section 3).
                *   The `GridView` will be scrollable if the number of templates exceeds the visible area of the bottom sheet, managed by the `ScrollController` from the `DraggableScrollableSheet`.

## 3. `TemplateListItem` Widget Design (Conceptual)

This widget represents a single item in the template grid.

*   **Structure:** Likely a `Card` or a `Container` with `InkWell` for tap feedback.
*   **Content:**
    *   **Thumbnail Image:**
        *   An `Image.network()` widget to display the template's `thumbnail_url` (fetched from the `templates` table).
        *   Must include robust `loadingBuilder` (e.g., a shimmer effect or a smaller placeholder icon) and `errorBuilder` (e.g., a broken image icon).
        *   `fit: BoxFit.cover` or `BoxFit.contain` depending on desired appearance within the grid cell.
    *   **Template Name:**
        *   A `Text` widget displaying the template's `name`.
        *   Positioned either below the thumbnail or as an overlay at the bottom of the thumbnail (with a semi-transparent background for readability).
        *   Should handle text overflow gracefully (e.g., `TextOverflow.ellipsis`).
*   **Interactivity:**
    *   The entire item will be tappable.
    *   `onTap` action will select the template.

## 4. Interaction Flow

1.  **User Action:** User taps the "Choose Template" button on the `TextInputScreen`.
2.  **Method Call:** The `_selectTemplate()` method in `_TextInputScreenState` is invoked.
3.  **Sheet Presentation:** `showModalBottomSheet()` is called, rendering the `DraggableScrollableSheet` which contains the template browser UI.
4.  **Data Fetching (Inside Bottom Sheet):**
    *   The template browser widget (likely a `StatefulWidget` itself) initiates fetching of templates from the Supabase `templates` table (e.g., in its `initState` using a `FutureBuilder` or a dedicated state management solution).
    *   **UI Update:** The UI within the sheet updates based on the fetching state: Loading -> Error/Empty/Data.
5.  **User Browsing:** User scrolls through the `GridView` of templates.
6.  **Template Selection:** User taps on a `TemplateListItem`.
7.  **`onTap` Callback:** The `onTap` callback of the selected `TemplateListItem`:
    *   Calls `Navigator.pop(context, selectedTemplateData)`, passing the data of the chosen template (e.g., a `Map` or a `Template` object containing `id`, `name`, `image_url`).
8.  **Update `TextInputScreen`:**
    *   The `_selectTemplate()` method in `_TextInputScreenState` receives the selected template data from the `await showModalBottomSheet(...)` call.
    *   `_TextInputScreenState.setState()` is called to update `_selectedTemplateId`, `_selectedTemplateName`, and `_selectedTemplateImageUrl`.
    *   The UI of `TextInputScreen` rebuilds to display the name and/or preview of the selected template.

## 5. Key Considerations

*   **Responsiveness:** The `GridView`'s `crossAxisCount` should be adaptive to screen size. The `DraggableScrollableSheet` itself is inherently responsive to height.
*   **Performance:**
    *   Efficiently load and display template thumbnails, especially with potentially large lists.
    *   Consider pagination or infinite scrolling within the bottom sheet if the number of templates is very large (though `DraggableScrollableSheet` with `ListView.builder`/`GridView.builder` already virtualizes items).
    *   Use optimized thumbnail URLs if available from Supabase Storage (e.g., via transformations, though this might require additional setup).
*   **Accessibility:**
    *   Ensure template names are clearly legible.
    *   Grid items should have sufficient tap target sizes.
    *   Consider semantic labels for images if names are not always visible or descriptive enough.
*   **State Management (within Bottom Sheet):** The template browser within the bottom sheet will need its own state management for handling loading, data, error, and empty states for the template list.

This design provides a user-friendly and modern approach for selecting templates, leveraging common Flutter UI patterns.

