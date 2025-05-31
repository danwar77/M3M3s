# Advanced Color Picker Implementation Plan

## Date: 2025-05-31

## 1. Objective
To enhance the text color selection capabilities in `MemeDisplayScreen` by integrating an advanced color picker, allowing users a wider range of color choices beyond the current preset buttons for both text fill and text stroke.

## 2. Chosen Package
*   **Package:** `flutter_colorpicker`
*   **Rationale:** It is a popular, well-maintained, and feature-rich package offering various picker styles (e.g., Material, Block, Wheel, full ColorPicker with sliders). This saves significant development time compared to building a custom picker.
*   **User Action Required:** Add `flutter_colorpicker: ^1.0.3` (or latest version) to `pubspec.yaml` and run `flutter pub get`.

## 3. UI Integration Strategy

*   **Augment Existing Controls:** The advanced color picker will augment, not replace, the existing simple color swatch buttons. This provides users with both quick common choices and advanced options.
*   **Trigger Mechanism:**
    *   For **Text Fill Color (`_textColor`):** A new button (e.g., `TextButton("More Colors...")` or an `IconButton` with a palette icon) will be added alongside or after the row of existing fill color swatch buttons.
    *   For **Text Stroke Color (`_textStrokeColor`):** Similarly, a "More Colors..." button or icon will be added alongside the stroke color swatch buttons.
*   **Modal Dialog:** Tapping the "More Colors..." button will open a modal dialog (`showDialog`) containing the `ColorPicker` widget from the `flutter_colorpicker` package.

## 4. `ColorPicker` Widget Usage (from `flutter_colorpicker`)

*   **Picker Type:** The comprehensive `ColorPicker` widget (which includes HSV/RGB/Material selectors) will be used to offer maximum flexibility.
*   **Dialog Implementation Sketch:**
    ```dart
    // Method to show color picker dialog, adaptable for fill or stroke
    // void _showAdvancedColorPicker({required bool forStroke}) {
    //   Color currentColor = forStroke ? _textStrokeColor : _textColor;
    //   Color tempPickerColor = currentColor; // Temporary color for the picker

    //   showDialog(
    //     context: context,
    //     builder: (BuildContext context) {
    //       return AlertDialog(
    //         title: Text(forStroke ? 'Pick an Outline Color' : 'Pick a Fill Color'),
    //         content: SingleChildScrollView(
    //           child: ColorPicker(
    //             pickerColor: currentColor, // Initial color for the picker
    //             onColorChanged: (Color color) {
    //               tempPickerColor = color; // Update temporary color
    //             },
    //             // enableAlpha: false, // Optional: disable alpha if not needed
    //             // displayThumbColor: true,
    //             // pickerAreaHeightPercent: 0.8,
    //           ),
    //         ),
    //         actions: <Widget>[
    //           TextButton(
    //             child: const Text('Cancel'),
    //             onPressed: () => Navigator.of(context).pop(),
    //           ),
    //           ElevatedButton(
    //             child: const Text('Select'),
    //             onPressed: () {
    //               setState(() {
    //                 if (forStroke) {
    //                   _textStrokeColor = tempPickerColor;
    //                 } else {
    //                   _textColor = tempPickerColor;
    //                 }
    //               });
    //               Navigator.of(context).pop();
    //             },
    //           ),
    //         ],
    //       );
    //     },
    //   );
    // }
    ```

## 5. State Management

*   The existing state variables `_textColor` (for fill) and `_textStrokeColor` (for stroke) in `_MemeDisplayScreenState` will be updated by the advanced color picker upon confirmation from the dialog.
*   The `_buildMemePreview()` method will automatically reflect these color changes as it already uses these state variables for styling the text.

## 6. Impact on Existing Simple Color Buttons

*   The simple color swatch buttons (`_buildColorButton` and `_buildStrokeColorButton`) will remain functional for quick selections.
*   The UI should clearly differentiate the "More Colors..." button from these swatches.
*   A small visual indicator (e.g., a colored box or circle) showing the *current* `_textColor` and `_textStrokeColor` should be present near their respective "More Colors..." buttons, so the user can see the active color chosen by either method.

## 7. Implementation Steps (Following this Plan)

1.  (User) Add `flutter_colorpicker` to `pubspec.yaml`.
2.  Add new state variable for advanced text color (already have `_textColor`, `_textStrokeColor`). (Step 6 of main plan - covered)
3.  Implement UI control (button) to launch the advanced color picker dialog. (Step 7 of main plan)
4.  Implement the dialog itself using `ColorPicker`. (Step 7 of main plan)
5.  Ensure `_buildMemePreview` correctly uses the updated colors. (Step 8 of main plan - already does)

This plan provides a clear path to integrating a powerful color selection tool, enhancing user customization options.
```
