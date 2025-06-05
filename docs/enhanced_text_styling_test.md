# Conceptual Test: Enhanced Text Styling (`MemeDisplayScreen`)

## Date: 2025-05-31

## 1. Objective
To conceptually test the user flow and state management for the newly implemented enhanced text styling features in `MemeDisplayScreen`, specifically text stroke (outline) and advanced color pickers for both fill and stroke.

## 2. Test Scenarios & Verifications

### Scenario 2.1: Text Stroke Enable/Disable

1.  **User Action:** Taps the "Enable Text Outline" `SwitchListTile`.
    *   **UI Control:** `SwitchListTile` for `_isTextStrokeEnabled`.
    *   **Initial State (Example):** `_isTextStrokeEnabled = true`. Stroke width and color controls are visible.
    *   **State Change:** `_isTextStrokeEnabled` toggles (e.g., to `false`). `setState()` is called.
    *   **`_buildMemePreview()` Output:**
        *   If toggled OFF: The text stroke disappears. The text might now show the fallback shadow effect (if `!_isTextStrokeEnabled && _textStrokeWidth <=0` condition is met, or if explicitly added when stroke is off).
        *   If toggled ON: The text stroke reappears using current `_textStrokeColor` and `_textStrokeWidth`. Fallback shadows are removed.
    *   **Conditional UI:** If `_isTextStrokeEnabled` is `false`, the "Outline Width" slider and "Outline Color" selection UI become hidden. If `true`, they become visible.
    *   *Verification:* Toggling the switch correctly updates the text appearance and visibility of related controls.

### Scenario 2.2: Text Stroke Width Adjustment

1.  **User Action:** Drags the "Outline Width" `Slider`.
    *   **UI Control:** `Slider` for `_textStrokeWidth`. (Assumes `_isTextStrokeEnabled = true`).
    *   **State Change:** `_textStrokeWidth` updates to the slider's value. `setState()` is called.
    *   **`_buildMemePreview()` Output:** The thickness of the text stroke changes dynamically as the slider is moved.
    *   *Verification:* Stroke width updates correctly in the preview. The displayed numerical value next to the slider also updates.

### Scenario 2.3: Text Stroke Color - Simple Swatch Selection

1.  **User Action:** Taps one of the simple stroke color swatch buttons (e.g., `_buildStrokeColorButton(Colors.white, context)`).
    *   **UI Control:** `InkWell` inside `_buildStrokeColorButton`. (Assumes `_isTextStrokeEnabled = true`).
    *   **State Change:** `_textStrokeColor` updates to the selected color (e.g., `Colors.white`). `setState()` is called.
    *   **`_buildMemePreview()` Output:** The color of the text stroke changes to the selected color.
    *   **UI Feedback:** The border of the selected `_buildStrokeColorButton` updates to indicate it's the active stroke color. The `IconButton` for the advanced stroke color picker also updates its icon color to `_textStrokeColor`.
    *   *Verification:* Stroke color updates correctly from swatches.

### Scenario 2.4: Text Stroke Color - Advanced Color Picker

1.  **User Action:** Taps the "More Outline Colors" `IconButton`.
    *   **UI Control:** `IconButton` next to stroke color swatches. (Assumes `_isTextStrokeEnabled = true`).
    *   **Key Method Called:** `_showAdvancedColorPicker(forStroke: true)`.
    *   **UI Feedback:** An `AlertDialog` containing the `ColorPicker` widget appears. The picker initially shows `_textStrokeColor`.

2.  **User Action:** User selects a new color in the `ColorPicker` and taps "Select Color".
    *   **UI Control:** `ColorPicker` widget and "Select Color" `ElevatedButton` in the dialog.
    *   **State Change:** `_textStrokeColor` updates to the color chosen in the picker. `setState()` is called (within `_showAdvancedColorPicker` which then triggers rebuild of `MemeDisplayScreen`).
    *   **`_buildMemePreview()` Output:** The color of the text stroke changes to the newly selected advanced color.
    *   **UI Feedback:** Dialog dismisses. The `IconButton` for the advanced stroke color picker updates its icon color to the new `_textStrokeColor`.
    *   *Verification:* Stroke color updates correctly from the advanced picker.

### Scenario 2.5: Text Fill Color - Advanced Color Picker

1.  **User Action:** Taps the "More Fill Colors" `IconButton`.
    *   **UI Control:** `IconButton` next to fill color swatches.
    *   **Key Method Called:** `_showAdvancedColorPicker(forStroke: false)`.
    *   **UI Feedback:** An `AlertDialog` containing the `ColorPicker` widget appears. The picker initially shows `_textColor`.

2.  **User Action:** User selects a new color in the `ColorPicker` and taps "Select Color".
    *   **UI Control:** `ColorPicker` widget and "Select Color" `ElevatedButton` in the dialog.
    *   **State Change:** `_textColor` updates to the color chosen in the picker. `setState()` is called.
    *   **`_buildMemePreview()` Output:** The fill color of the text changes to the newly selected advanced color.
    *   **UI Feedback:** Dialog dismisses. The `IconButton` for the advanced fill color picker updates its icon color to the new `_textColor`.
    *   *Verification:* Fill color updates correctly from the advanced picker.

### Scenario 2.6: Interaction with Other Text Style Controls

1.  **User Action:** While text stroke is enabled and visible, user changes Font Size or Font Family.
    *   **UI Controls:** `Slider` for `_fontSize`, `DropdownButton` for `_fontFamily`.
    *   **State Change:** `_fontSize` or `_fontFamily` updates. `setState()` is called.
    *   **`_buildMemePreview()` Output:** Both the text fill and the text stroke should reflect the new font size/family simultaneously. The stroke should scale proportionally with the font size.
    *   *Verification:* Stroke correctly adapts to changes in other text style properties like font size and family.

2.  **User Action:** Disable stroke, then change fill color, then re-enable stroke.
    *   **UI Controls:** Stroke `SwitchListTile`, fill color buttons/picker.
    *   **State Changes:** `_isTextStrokeEnabled` (false, then true), `_textColor` changes.
    *   **`_buildMemePreview()` Output:**
        *   Stroke disappears.
        *   Fill color changes.
        *   Stroke reappears with its previously set color (`_textStrokeColor`) and width (`_textStrokeWidth`), not affected by the intermediate fill color change.
    *   *Verification:* Fill and stroke color states are managed independently.

### Scenario 2.7: Operations during Save/Share

1.  **User Action:** User initiates a "Save" or "Share" operation.
    *   **State Change:** `_isSaving` or `_isSharing` becomes `true`.
2.  **User Action:** User attempts to interact with any of the new styling controls (Enable Stroke Switch, Stroke Width Slider, Stroke Color Swatches, Advanced Color Picker IconButtons for fill or stroke).
    *   **UI Controls:** All relevant controls.
    *   **Expected Behavior:** All these controls should be disabled (e.g., `onChanged: null`, `onPressed: null`). The `_showAdvancedColorPicker` method should return early if `_isSaving || _isSharing`.
    *   *Verification:* UI controls for text styling are correctly disabled during save/share operations to prevent state changes.

## 3. Conclusion
The conceptual walkthrough indicates that the planned UI controls and state management for text stroke and advanced color selection should function correctly.
*   Enabling/disabling stroke correctly toggles its visibility and the visibility of its specific controls.
*   Stroke width and color (via simple swatches or advanced picker) update the respective state variables, and the preview reflects these changes.
*   Advanced color picker for fill color also correctly updates its state and the preview.
*   The stroke rendering adapts to changes in font size and family.
*   Fill and stroke color states are independent.
*   Controls are correctly disabled during save/share operations.

The implementation of these features, based on the current plan and code structure, appears logically sound and should provide the intended user experience.
```
