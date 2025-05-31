# Text Stroke/Outline Implementation Plan

## Date: 2025-05-31

## 1. Objective
To implement a clear and controllable text stroke (outline) effect for meme text on the `MemeDisplayScreen`. The current method using multiple `TextStyle.shadows` provides a basic outline but lacks fine control over thickness and appearance.

## 2. Evaluated Options

### Option A: Enhancing `TextStyle.shadows`
*   **Description:** Add more `Shadow` objects with various offsets to simulate a thicker outline.
*   **Pros:** Uses a single `Text` widget.
*   **Cons:** Difficult to achieve a consistent, clean stroke. Control over true "thickness" is indirect. Performance may degrade with many shadows.

### Option B: `Stack` with Two `Text` Widgets
*   **Description:**
    1.  A background `Text` widget for the stroke:
        *   `TextStyle.foreground` uses `Paint()..style = PaintingStyle.stroke ..strokeWidth = newStrokeWidth ..color = newStrokeColor`.
    2.  A foreground `Text` widget for the fill:
        *   `TextStyle.color` uses the main text fill color.
    *   Both widgets render the same text content.
*   **Pros:** Good control over stroke color and width. Produces a clean, distinct outline. Relatively straightforward to implement.
*   **Cons:** Requires two `Text` widgets per text element (top/bottom).

### Option C: `CustomPaint` with `TextPainter`
*   **Description:** Manually draw the text twice (once for stroke, once for fill) using `TextPainter` on a `Canvas`.
*   **Pros:** Maximum rendering control.
*   **Cons:** Significantly more complex implementation. Likely overkill for this specific effect.

## 3. Chosen Approach: Option B - `Stack` with Two `Text` Widgets

**Rationale:**
Option B provides the best balance of visual quality, control over stroke properties (color, width), and implementation effort. It's a common and effective method in Flutter for achieving this effect.

**Implementation Details (Conceptual):**

*   The existing `_buildMemePreview()` in `_MemeDisplayScreenState` will be modified.
*   For each piece of text (top and bottom), a `Stack` will be used.
*   **Stroke Text Widget (Bottom Layer):**
    ```dart
    Text(
      _topTextController.text.toUpperCase(), // Or respective text variable
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: _fontFamily,
        fontSize: _fontSize,
        foreground: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = _textStrokeWidth // New state variable
          ..color = _textStrokeColor,    // New state variable
        // fontWeight: FontWeight.bold, // Potentially omit or make configurable for stroke
      ),
    )
    ```
*   **Fill Text Widget (Top Layer):**
    ```dart
    Text(
      _topTextController.text.toUpperCase(), // Or respective text variable
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: _fontFamily,
        fontSize: _fontSize,
        color: _textColor, // Existing state variable for fill color
        fontWeight: FontWeight.bold,
        shadows: null, // Remove previous shadow-based outline
      ),
    )
    ```
*   The existing `shadows` property in the main text's `TextStyle` (which created a faux outline) will be removed or made conditional (disabled if true stroke is enabled).
*   State variables `_isTextStrokeEnabled`, `_textStrokeColor`, and `_textStrokeWidth` will be added to `_MemeDisplayScreenState` and controlled by new UI elements.

This approach will allow users to toggle the stroke, change its color, and adjust its thickness.
```
