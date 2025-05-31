# Conceptual Test: Paginated Template Browser Flow in TextInputScreen

## Date: 2024-03-11

## Objective:
To conceptually test the user flow, state management, and UI feedback for the paginated template browser within the `_selectTemplate()` modal bottom sheet in `TextInputScreen`. This includes initial load, infinite scrolling, error handling, and empty state scenarios.

## State Variables Involved:
*   `_allFetchedTemplates` (List<TemplateInfo>)
*   `_templatesCurrentPage` (int)
*   `_templatesPageSize` (final int)
*   `_isLoadingInitialTemplates` (bool)
*   `_isLoadingMoreTemplates` (bool)
*   `_hasMoreTemplates` (bool)
*   `_fetchTemplatesError` (Object?)
*   `_templateScrollController` (ScrollController)

## Main Method: `_fetchTemplates({bool isInitialFetch = false})`
## UI Context: Modal Bottom Sheet in `_selectTemplate()`

---

## Test Scenarios & Verifications:

**Scenario 1: Initial Load - Success (Multiple Pages of Data)**
1.  **Action:** User taps "Choose Template", invoking `_selectTemplate()`.
2.  **Initial Call:** `_selectTemplate()` sees `_allFetchedTemplates` is empty and `_fetchTemplatesError` is null, so it calls `_fetchTemplates(isInitialFetch: true)`.
3.  **`_fetchTemplates(isInitialFetch: true)` starts:**
    *   `setState`: `_isLoadingInitialTemplates = true`, `_fetchTemplatesError = null`, `_templatesCurrentPage = 0`, `_allFetchedTemplates` is cleared, `_hasMoreTemplates = true`.
4.  **Modal UI (Sheet Content):** Displays the initial loading state: centered `CircularProgressIndicator` and "Loading templates..." text.
5.  **Data Fetch:** Supabase query for `range(0, _templatesPageSize - 1)` is executed. Assume it returns a full page of 20 templates.
6.  **State Update (Success):**
    *   `setState`: `_allFetchedTemplates` is populated with the 20 items. `_templatesCurrentPage` becomes 1. `_hasMoreTemplates` remains `true` (as `newTemplates.length == _templatesPageSize`). `_fetchTemplatesError` remains `null`.
    *   `setState` (in `finally`): `_isLoadingInitialTemplates = false`.
7.  **Modal UI Updates:** The `GridView.builder` displays the first 20 `TemplateListItem`s. Since `_hasMoreTemplates` is true and `_allFetchedTemplates` is not empty, an extra slot for the "load more" indicator is added to `itemCount`. In this slot, `_isLoadingMoreTemplates` is false, so a `SizedBox.shrink()` is rendered (no visible loader).
*   **Verification:** **PASS.** Correct initial data display, UI reflects the loaded state, and the setup for infinite scroll is ready.

**Scenario 2: Initial Load - Success (Single Page of Data - Less than `_pageSize`)**
1.  (Steps 1-4 from Scenario 1 occur).
2.  **Data Fetch:** Supabase query for `range(0, _templatesPageSize - 1)` returns (e.g.) 5 items.
3.  **State Update (Success):**
    *   `setState`: `_allFetchedTemplates` is populated with 5 items. `_templatesCurrentPage` becomes 1. `_hasMoreTemplates` becomes `false` (as `newTemplates.length < _templatesPageSize`). `_fetchTemplatesError` remains `null`.
    *   `setState` (in `finally`): `_isLoadingInitialTemplates = false`.
4.  **Modal UI Updates:** `GridView.builder` displays the 5 items. The `itemCount` does not include an extra slot for a "load more" indicator because `_hasMoreTemplates` is now `false`.
*   **Verification:** **PASS.** Correct data display, `_hasMoreTemplates` is accurately set, and no "load more" UI is shown.

**Scenario 3: Initial Load - Success (No Data)**
1.  (Steps 1-4 from Scenario 1 occur).
2.  **Data Fetch:** Supabase query for `range(0, _templatesPageSize - 1)` returns 0 items.
3.  **State Update (Success):**
    *   `setState`: `_allFetchedTemplates` remains empty. `_templatesCurrentPage` becomes 1. `_hasMoreTemplates` becomes `false`. `_fetchTemplatesError` remains `null`.
    *   `setState` (in `finally`): `_isLoadingInitialTemplates = false`.
4.  **Modal UI Updates:** The condition `_allFetchedTemplates.isEmpty && !_hasMoreTemplates && !_isLoadingInitialTemplates` becomes true. The UI displays the "No templates found." message with an icon and a "Refresh" button.
*   **Verification:** **PASS.** Correct empty state display with a functional "Refresh" button.

**Scenario 4: Initial Load - Failure**
1.  (Steps 1-2 from Scenario 1 occur).
2.  **`_fetchTemplates(isInitialFetch: true)` starts:**
    *   `setState`: `_isLoadingInitialTemplates = true`, etc.
3.  **Data Fetch:** Supabase query fails (e.g., network error). A `PostgrestException` or other exception is caught.
4.  **State Update (Error):**
    *   `setState`: `_fetchTemplatesError` is set to the caught error object. `_hasMoreTemplates` is set to `false` (as per current error handling in `_fetchTemplates`).
    *   `setState` (in `finally`): `_isLoadingInitialTemplates = false`.
5.  **Modal UI Updates:** The condition `_fetchTemplatesError != null && _allFetchedTemplates.isEmpty` becomes true. The UI displays the "Oops! Couldn't load templates..." error message, the error string, an error icon, and a "Retry" button.
*   **Verification:** **PASS.** Correct error state display with a functional "Retry" button.

**Scenario 5: Infinite Scroll - Load More Success (Following Scenario 1)**
1.  Initial 20 items are loaded and displayed. User scrolls the `GridView`.
2.  **`_templateScrollController` Listener:** Triggers when scroll position is near the bottom, and conditions (`_hasMoreTemplates` is true, not already loading, no error) are met. `_fetchTemplates(isInitialFetch: false)` is called.
3.  **`_fetchTemplates(isInitialFetch: false)` starts:**
    *   `setState`: `_isLoadingMoreTemplates = true`.
4.  **Modal UI Updates:** The `GridView.builder`'s last item (the extra slot) now renders `Center(child: Padding(padding: const EdgeInsets.all(16.0), child: SizedBox(height: 24, width: 24, child:CircularProgressIndicator(strokeWidth: 2.5))))` because `_isLoadingMoreTemplates` is true.
5.  **Data Fetch:** `_templatesCurrentPage` is 1. Supabase query for `range(20, 39)` executes. Assume it returns 15 more items.
6.  **State Update (Success):**
    *   `setState`: `_allFetchedTemplates` now contains 35 items. `_templatesCurrentPage` becomes 2. `_hasMoreTemplates` becomes `false` (as 15 < 20). `_fetchTemplatesError` is `null`.
    *   `setState` (in `finally`): `_isLoadingMoreTemplates = false`.
7.  **Modal UI Updates:** `GridView.builder` now displays all 35 items. The "load more" indicator slot is no longer part of `itemCount` because `_hasMoreTemplates` is false.
*   **Verification:** **PASS.** Infinite scroll triggers, shows a loading indicator, appends new items, and correctly updates `_hasMoreTemplates`.

**Scenario 6: Infinite Scroll - Load More Failure**
1.  Initial 20 items loaded. User scrolls, `_fetchTemplates(isInitialFetch: false)` is called.
2.  `setState`: `_isLoadingMoreTemplates = true`. UI shows "load more" indicator.
3.  Supabase query for the second page fails.
4.  **State Update (Error):**
    *   `setState`: `_fetchTemplatesError` is set. `_hasMoreTemplates` is set to `false`.
    *   `setState` (in `finally`): `_isLoadingMoreTemplates = false`.
5.  **Modal UI Updates:**
    *   The `GridView` still displays the original 20 items.
    *   The "load more" indicator slot is removed from `itemCount` because `_hasMoreTemplates` is false.
    *   **Feedback Issue:** The error stored in `_fetchTemplatesError` is not directly displayed to the user if there are already items in `_allFetchedTemplates`. The list simply stops extending.
*   **Verification:** **PARTIALLY PASS.** The list correctly shows existing items and stops trying to load more. However, there is no explicit feedback for the "load more" failure.
    *   *Recommendation from previous review (Step 7) stands:* A `SnackBar` in `_fetchTemplates` for `!isInitialFetch` errors would improve this.

**Scenario 7: Infinite Scroll - No More Items to Load**
1.  (As in Scenario 5, but the second fetch returns, e.g., 5 items, and `_templatesPageSize` is 20).
2.  **State Update (Success):**
    *   `setState`: `_allFetchedTemplates` adds the 5 items. `_templatesCurrentPage` increments. `_hasMoreTemplates` becomes `false`.
    *   `setState` (in `finally`): `_isLoadingMoreTemplates = false`.
3.  **Modal UI Updates:** `GridView.builder` displays all items. The "load more" indicator slot is removed as `_hasMoreTemplates` is false.
*   **Verification:** **PASS.** Infinite scroll correctly terminates when the fetched items are less than the page size.

**Scenario 8: User Taps "Retry" (Following Scenario 4 - Initial Load Failure)**
1.  UI shows the full-screen error message with "Retry" button.
2.  **Action:** User taps "Retry".
3.  **`onPressed` handler:** Calls `_fetchTemplates(isInitialFetch: true)`.
4.  **`_fetchTemplates(isInitialFetch: true)` starts:**
    *   `setState`: `_isLoadingInitialTemplates = true`, `_fetchTemplatesError = null`, `_templatesCurrentPage = 0`, `_allFetchedTemplates.clear()`, `_hasMoreTemplates = true`.
5.  **Modal UI Updates:** Shows the initial loading indicator.
6.  Flow proceeds like Scenario 1 (or 2, 3, or 4 again depending on fetch outcome).
*   **Verification:** **PASS.** Retry logic correctly resets error state and re-initiates the initial fetching process.

**Scenario 9: User Taps "Refresh" (Following Scenario 3 - Initial Load, No Data)**
1.  UI shows "No templates found." message with "Refresh" button.
2.  **Action:** User taps "Refresh".
3.  **`onPressed` handler:** Calls `_fetchTemplates(isInitialFetch: true)`.
4.  **`_fetchTemplates(isInitialFetch: true)` starts:**
    *   `setState`: `_isLoadingInitialTemplates = true`, `_fetchTemplatesError = null`, `_templatesCurrentPage = 0`, `_allFetchedTemplates.clear()`, `_hasMoreTemplates = true`.
5.  **Modal UI Updates:** Shows the initial loading indicator.
6.  Flow proceeds like Scenario 1 (or 2, 3, or 4 again).
*   **Verification:** **PASS.** Refresh logic correctly re-initiates the initial fetching process.

## Overall Conclusion:

The paginated template browser flow within `TextInputScreen` is **largely robust and handles most states correctly.**
*   Initial data loading, including success, empty, and error states, is well-managed.
*   Infinite scrolling correctly loads more data and terminates when no more items are available.
*   Retry and refresh mechanisms function as intended, allowing users to re-attempt fetching.
*   State variables (`_isLoadingInitialTemplates`, `_isLoadingMoreTemplates`, `_hasMoreTemplates`, `_fetchTemplatesError`, `_allFetchedTemplates`, `_templatesCurrentPage`) are updated appropriately to drive the UI.

**Identified Area for Improvement (as noted in previous review step):**
*   **Feedback for "Load More" Errors (Scenario 6):** When an error occurs during an infinite scroll fetch (i.e., not an initial load, so `_allFetchedTemplates` is not empty), the error is not explicitly shown to the user. The list just stops loading more. A `SnackBar` or a small error indicator at the bottom of the list could improve this.

Apart from this minor feedback enhancement for "load more" errors, the core pagination logic and UI state handling are sound.
```
