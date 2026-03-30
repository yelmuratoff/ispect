# Inspector Upstream Contributions

## Контекст

ispect содержит ~3000 строк кастомного inspector кода поверх `inspector: ^3.1.0`. Цель — перенести лучшие фичи upstream в `inspector` пакет (kekland/inspector), чтобы ispect мог удалить свою реализацию и использовать `inspector: ^5.0.0` напрямую.

**Референс-реализация:** `packages/ispect/lib/src/features/inspector/src/`

**Репо inspector:** https://github.com/kekland/inspector

---

## PR #1: Tap-tap Compare Mode (вместо hold+hover)

### Проблема

Текущий compare в inspector работает через зажатие Y + hover:
- Не работает на мобайле (нет клавиатуры)
- Compare пропадает при отпускании Y — нельзя зафиксировать два виджета
- Нет UI-кнопки для входа в compare

### Что сделать

#### 1. Новый режим `InspectorMode.compareSelect`

Добавить в enum:
```dart
enum InspectorMode {
  idle,
  inspector,
  inspectAndCompare, // существующий — оставить для обратной совместимости
  compareSelect,     // НОВЫЙ: ожидание второго tap'а
  colorPicker,
  zoom,
}
```

#### 2. Методы на InspectorController

```dart
/// Enters compare mode: the next tap will select the second widget
/// to compare against the currently selected one.
/// Called from the UI "Compare" button (mobile) or Y key (desktop).
void enterCompareMode() {
  if (currentRenderBoxNotifier.value == null) return;
  modeNotifier.value = InspectorMode.compareSelect;
  comparedRenderBoxNotifier.value = null;
}

/// Exits compare mode and clears comparison data.
void exitCompareMode() {
  modeNotifier.value = InspectorMode.inspector;
  comparedRenderBoxNotifier.value = null;
}
```

#### 3. Tap handling в compareSelect

В `onTap` / `onPointerDown`:
```dart
if (modeNotifier.value == InspectorMode.compareSelect) {
  final compared = _computeBoxInfoAt(pointerOffset);
  if (compared != null &&
      compared.targetRenderBox !=
          currentRenderBoxNotifier.value?.targetRenderBox) {
    comparedRenderBoxNotifier.value = compared;
  }
  modeNotifier.value = InspectorMode.inspector; // выход после выбора
  return;
}
```

#### 4. Y key — toggle вместо hold

В `KeyboardHandler`:
```dart
// Было: Y down → enter, Y up → exit
// Стало: Y down → toggle
void _onCompareKeyDown() {
  if (modeNotifier.value == InspectorMode.compareSelect) {
    exitCompareMode();
  } else {
    enterCompareMode();
  }
}
```

#### 5. Auto-cleanup при выходе из inspector

```dart
void _onInspectorStateChanged(bool isEnabled) {
  if (!isEnabled) {
    currentRenderBoxNotifier.value = null;
    exitCompareMode(); // сбросить compare state
  }
}
```

### Чеклист

- [ ] `InspectorMode.compareSelect` добавлен в enum
- [ ] `enterCompareMode()` / `exitCompareMode()` на InspectorController
- [ ] Tap в compareSelect выбирает второй виджет и фиксирует оба
- [ ] Защита от сравнения виджета с самим собой
- [ ] Y key toggle (не hold)
- [ ] Выход из inspector → автоматический exitCompareMode
- [ ] Обратная совместимость: `inspectAndCompare` остается для hold+hover use-case
- [ ] Тесты: enter → tap → оба зафиксированы; enter → cancel; same widget rejected
- [ ] `dart analyze --fatal-infos && dart test`

### Acceptance Criteria

1. На мобайле: tap виджет → нажать "Compare" → tap второй виджет → оба подсвечены, расстояния показаны
2. На десктопе: tap виджет → Y → tap второй → оба зафиксированы; Y снова → compare сброшен
3. При tap того же виджета — ничего не происходит
4. При выключении inspector — compare state очищается

**Референс:** `inspector.dart:238-264` (_onTap), `inspector.dart:304-325` (enter/exit/onCompareStateChanged)

---

## PR #2: Direction-aware Distance Calculation

### Проблема

Текущий алгоритм в inspector считает только LTRB edge distances (числа в панели). Не различает:
- Gap между разнесенными виджетами vs overlap alignment
- Направление (→ vs ←)
- Нет startOffset/endOffset для рисования линий

### Что сделать

#### 1. Data model

```dart
enum CompareSide { left, top, right, bottom }

class CompareDistance {
  const CompareDistance({
    required this.side,
    required this.value,
    required this.icon,
    required this.startOffset,
    required this.endOffset,
    required this.isHorizontal,
  });

  final CompareSide side;
  final double value;         // logical units (divided by scale)
  final IconData icon;        // direction arrow
  final Offset startOffset;   // screen coords for drawing lines
  final Offset endOffset;     // screen coords for drawing lines
  final bool isHorizontal;
}
```

#### 2. Алгоритм `computeCompareDistances`

```dart
List<CompareDistance> computeCompareDistances(
  Rect from,
  Rect to, {
  double scale = 1.0,
}) {
  final hSeparated = from.right <= to.left || to.right <= from.left;
  final vSeparated = from.bottom <= to.top || to.bottom <= from.top;
  final results = <CompareDistance>[];

  // --- Случай 1: Horizontal gap ---
  if (hSeparated) {
    final y = from.center.dy;
    if (from.right <= to.left) {
      results.add(CompareDistance(
        side: CompareSide.right,
        value: (to.left - from.right) / scale,
        icon: Icons.arrow_forward,
        startOffset: Offset(from.right, y),
        endOffset: Offset(to.left, y),
        isHorizontal: true,
      ));
    } else {
      results.add(CompareDistance(
        side: CompareSide.left,
        value: (from.left - to.right) / scale,
        icon: Icons.arrow_back,
        startOffset: Offset(to.right, y),
        endOffset: Offset(from.left, y),
        isHorizontal: true,
      ));
    }
  }

  // --- Случай 2: Vertical gap ---
  if (vSeparated) {
    final x = to.center.dx;
    if (from.bottom <= to.top) {
      results.add(CompareDistance(
        side: CompareSide.bottom,
        value: (to.top - from.bottom) / scale,
        icon: Icons.arrow_downward,
        startOffset: Offset(x, from.bottom),
        endOffset: Offset(x, to.top),
        isHorizontal: false,
      ));
    } else {
      results.add(CompareDistance(
        side: CompareSide.top,
        value: (from.top - to.bottom) / scale,
        icon: Icons.arrow_upward,
        startOffset: Offset(x, to.bottom),
        endOffset: Offset(x, from.top),
        isHorizontal: false,
      ));
    }
  }

  // --- Случай 3: Overlap на обоих осях → LTRB alignment ---
  if (!hSeparated && !vSeparated) {
    final left = (from.left - to.left).abs();
    final right = (from.right - to.right).abs();
    final top = (from.top - to.top).abs();
    final bottom = (from.bottom - to.bottom).abs();
    final midY = (from.center.dy + to.center.dy) / 2;
    final midX = (from.center.dx + to.center.dx) / 2;

    if (left > 0.5) {
      final minL = from.left < to.left ? from.left : to.left;
      final maxL = from.left > to.left ? from.left : to.left;
      results.add(CompareDistance(
        side: CompareSide.left,
        value: left / scale,
        icon: Icons.arrow_back,
        startOffset: Offset(minL, midY - 6),
        endOffset: Offset(maxL, midY - 6),
        isHorizontal: true,
      ));
    }
    // Аналогично right, top, bottom (см. референс)
  }

  return results;
}
```

#### 3. Интеграция в панель

Заменить текущий `_buildComparedRow()` на chips с иконками:
```dart
Wrap(
  spacing: 6,
  children: [
    for (final d in distances)
      Chip(
        avatar: Icon(d.icon, size: 14),
        label: Text('${d.value.toStringAsFixed(1)}'),
      ),
  ],
)
```

### Чеклист

- [ ] `CompareSide` enum и `CompareDistance` data class
- [ ] `computeCompareDistances()` — 3 сценария: H gap, V gap, overlap LTRB
- [ ] Все values делятся на `scale` (InteractiveViewer support)
- [ ] Distances < 0.5px игнорируются
- [ ] startOffset/endOffset в screen coords (для PR #3 — visual lines)
- [ ] Панель отображает direction-aware chips вместо плоских LTRB
- [ ] Unit тесты: separated H, separated V, separated both, overlapping, scaled
- [ ] `dart analyze --fatal-infos && dart test`

### Acceptance Criteria

1. Два виджета горизонтально → один distance chip "→ 24.0"
2. Два виджета вертикально → один chip "↓ 16.0"
3. Два виджета по диагонали → два chips: "→ 24.0", "↓ 16.0"
4. Два перекрывающихся → до 4 chips LTRB alignment
5. Внутри InteractiveViewer (scale=2.0) → values = visual / 2

**Референс:** `box_info_panel_widget.dart:621-794` (полная реализация)

---

## PR #3: Visual Distance Lines (CompareOverlayPainter)

### Проблема

Даже с direction-aware numbers (PR #2), нет визуальной связи между виджетами на canvas. Пользователь видит числа в панели, но не видит откуда до куда.

### Что сделать

#### 1. `CompareOverlayPainter` — новый CustomPainter

```dart
class CompareOverlayPainter extends CustomPainter {
  const CompareOverlayPainter({
    required this.boxInfoA,
    required this.boxInfoB,
    required this.lineColor,
  });

  final BoxInfo boxInfoA;
  final BoxInfo boxInfoB;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final from = boxInfoA.targetRectShifted;
    final to = boxInfoB.targetRectShifted;
    if (from == null || to == null) return;

    final distances = computeCompareDistances(
      from, to,
      scale: boxInfoA.scale,
    );

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final dashPaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (final d in distances) {
      _drawMeasurement(canvas, d.startOffset, d.endOffset, d.value,
        isHorizontal: d.isHorizontal,
        linePaint: linePaint,
        dashPaint: dashPaint,
      );
    }
  }
}
```

#### 2. Dashed line rendering

```dart
void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
  const dashLength = 4.0;
  const gapLength = 3.0;

  final dx = end.dx - start.dx;
  final dy = end.dy - start.dy;
  final distance = (end - start).distance;
  if (distance < 1) return;

  final unitDx = dx / distance;
  final unitDy = dy / distance;
  var drawn = 0.0;
  var drawing = true;

  while (drawn < distance) {
    final len = (drawing ? dashLength : gapLength).clamp(0, distance - drawn);
    if (drawing) {
      canvas.drawLine(
        Offset(start.dx + unitDx * drawn, start.dy + unitDy * drawn),
        Offset(start.dx + unitDx * (drawn + len), start.dy + unitDy * (drawn + len)),
        paint,
      );
    }
    drawn += len;
    drawing = !drawing;
  }
}
```

#### 3. Measurement caps (ticks на концах)

```dart
const cap = 4.0;
if (isHorizontal) {
  // Вертикальные ticks на концах горизонтальной линии
  canvas
    ..drawLine(Offset(from.dx, from.dy - cap), Offset(from.dx, from.dy + cap), linePaint)
    ..drawLine(Offset(to.dx, to.dy - cap), Offset(to.dx, to.dy + cap), linePaint);
} else {
  // Горизонтальные ticks на концах вертикальной линии
  canvas
    ..drawLine(Offset(from.dx - cap, from.dy), Offset(from.dx + cap, from.dy), linePaint)
    ..drawLine(Offset(to.dx - cap, to.dy), Offset(to.dx + cap, to.dy), linePaint);
}
```

#### 4. Distance label на canvas

```dart
void _drawLabel(Canvas canvas, String text, Offset position) {
  final builder = ui.ParagraphBuilder(
    ui.ParagraphStyle(textAlign: TextAlign.center, fontSize: 10),
  )
    ..pushStyle(ui.TextStyle(
      color: lineColor,
      fontSize: 10,
      fontWeight: FontWeight.bold,
      background: Paint()..color = const Color(0xCC000000),
    ))
    ..addText(text);

  final paragraph = builder.build()
    ..layout(const ui.ParagraphConstraints(width: 80));

  canvas.drawParagraph(
    paragraph,
    Offset(position.dx - paragraph.width / 2, position.dy - 6),
  );
}
```

#### 5. Overlay stack в BoxInfoWidget

```dart
Stack(
  children: [
    // 1. Primary box overlay (blue, 35% alpha)
    CustomPaint(painter: OverlayPainter(boxInfo: boxInfo, targetRectColor: blue)),

    // 2. Compared box overlay (green, 35% alpha)
    if (comparedBoxInfo?.targetRenderBox.attached ?? false)
      CustomPaint(painter: OverlayPainter(boxInfo: comparedBoxInfo!, targetRectColor: green)),

    // 3. Distance lines (green dashed + labels)  <-- НОВОЕ
    if (comparedBoxInfo?.targetRenderBox.attached ?? false)
      CustomPaint(painter: CompareOverlayPainter(
        boxInfoA: boxInfo,
        boxInfoB: comparedBoxInfo!,
        lineColor: green,
      )),

    // 4. Size badge
    _TargetBoxSizeWidget(boxInfo: boxInfo),

    // 5. Info panel (bottom)
    BoxInfoPanelWidget(...),
  ],
)
```

### Чеклист

- [ ] `CompareOverlayPainter` class с shouldRepaint
- [ ] `_drawDashedLine()` — 4px dash, 3px gap
- [ ] `_drawMeasurement()` — dashed line + caps + label
- [ ] `_drawLabel()` — ParagraphBuilder, bold 10pt, black bg
- [ ] Skip при distance < 0.5px
- [ ] Добавлен в overlay stack между compared overlay и size badge
- [ ] Все painters обернуты в `IgnorePointer`
- [ ] Цвета: primary=blue.shade700, compared=green.shade700
- [ ] `dart analyze --fatal-infos && dart test`

### Acceptance Criteria

1. Два разнесенных виджета → зеленая пунктирная линия с caps и "24.0" в середине
2. Два перекрывающихся → до 4 линий (L/T/R/B alignment)
3. Distance < 0.5px → линия не рисуется
4. Линии не перехватывают pointer events
5. При убирании compared widget → линии исчезают

**Референс:** `compare_overlay_painter.dart` (полный файл 180 строк), `box_info_widget.dart:34-90`

---

## PR #4: Enhanced Zoom (1-20x, circular overlay)

### Проблема

Текущий zoom ограничен (~5x), overlay прямоугольный, нет feedback'а уровня зума.

### Что сделать

#### 1. Расширить zoom range

```dart
// В InspectorController:
static const _minZoomScale = 1.0;
static const _maxZoomScale = 20.0;
static const _defaultZoomScale = 3.0;

void onScroll(double delta) {
  final current = zoomScaleNotifier.value;
  zoomScaleNotifier.value = (current + delta).clamp(_minZoomScale, _maxZoomScale);
}
```

#### 2. `CombinedOverlayWidget` — circular zoom preview

Triple-border design:
```dart
SizedBox.square(
  dimension: overlaySize, // 128-246px, lerp по zoom
  child: DecoratedBox(
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.fromBorderSide(BorderSide(
        color: borderColor,        // gray 20% alpha
        width: 20,
        strokeAlign: BorderSide.strokeAlignOutside,
      )),
    ),
    child: DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.fromBorderSide(BorderSide(
          color: pickedColor,      // цвет пикселя под курсором
          width: 18,
          strokeAlign: BorderSide.strokeAlignOutside,
        )),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.fromBorderSide(BorderSide(
            color: borderColor,
            width: 2,
            strokeAlign: BorderSide.strokeAlignOutside,
          )),
          boxShadow: [BoxShadow(blurRadius: 12, color: Colors.black12, spreadRadius: 1)],
        ),
        child: ClipOval(
          child: Stack(children: [
            // Zoomed image
            CustomPaint(painter: _ZoomPainter(...)),
            // Hex color label (top)
            // Zoom level indicator (auto-hiding)
            // Center color dot (10x10)
          ]),
        ),
      ),
    ),
  ),
)
```

#### 3. `_ZoomPainter` — image rendering

```dart
@override
void paint(Canvas canvas, Size size) {
  final halfSize = overlaySize / 2.0;
  final scale = (1 / pixelRatio) * zoomScale;

  canvas
    ..clipRect(Offset.zero & size)
    ..translate(halfSize, halfSize)
    ..scale(scale)
    ..drawImage(image, -imageOffset, Paint());
}
```

#### 4. `_ZoomLevelDisplay` — auto-hiding indicator

```dart
class _ZoomLevelDisplay extends StatefulWidget {
  // Shows "x3.0" for 1 second after zoom changes, then fades out
  // Timer-based with proper mounted checks
  // AnimatedOpacity for smooth fade
}
```

#### 5. Dynamic overlay size

```dart
const _overlayMinSize = 128.0;
const _overlayMaxSize = 246.0;

double _computeOverlaySize(double zoomScale) {
  final t = ((zoomScale - _minZoomScale) / (_maxZoomScale - _minZoomScale)).clamp(0.0, 1.0);
  return _overlayMinSize + t * (_overlayMaxSize - _overlayMinSize);
}
```

### Чеклист

- [ ] Zoom range: 1-20x (constants: min, max, default=3)
- [ ] `CombinedOverlayWidget` с triple-border circular design
- [ ] `_ZoomPainter` — clipRect + translate + scale + drawImage
- [ ] Hex color display внутри overlay (top area)
- [ ] Center color dot (10x10) с контрастной обводкой
- [ ] `_ZoomLevelDisplay` — auto-hide через 1 сек, AnimatedOpacity
- [ ] Dynamic overlay size: 128-246px по zoom level
- [ ] Scroll wheel → zoom in/out (clamp to range)
- [ ] `getPixelFromByteData(byteData, width, x, y)` — RGBA extraction
- [ ] `colorToHexString(color, {withAlpha})` — hex formatting
- [ ] `dart analyze --fatal-infos && dart test`

### Acceptance Criteria

1. Scroll → zoom от 1x до 20x, overlay растет от 128px до 246px
2. Circular overlay с тремя бордерами: gray → picked color → gray
3. Hex code пикселя отображается сверху
4. "x3.0" показывается при зуме, исчезает через 1 сек
5. Точка в центре показывает текущий цвет
6. При отпускании zoom → snackbar с цветом + кнопка копирования

**Референс:** `zoomable_color_picker/overlay.dart` (272 строки), `color_picker/utils.dart` (69 строк)

---

## PR #5: Box Decoration & Text Inspection

### Проблема

Панель показывает только widget type + size + padding. Дизайнер хочет видеть:
- Стили текста (font, size, weight, color, spacing)
- Декорации контейнера (border radius, shape, fill color)

### Что сделать

#### 1. Text inspection для `RenderParagraph`

**Detect:**
```dart
final targetBox = boxInfo.targetRenderBox;
if (targetBox is! RenderParagraph) return SizedBox.shrink();
```

**Extract spans рекурсивно:**
```dart
class _SpanInfo {
  const _SpanInfo({required this.text, required this.style});
  final String text;
  final TextStyle? style;
}

List<_SpanInfo> _extractSpanInfo(InlineSpan span, [List<_SpanInfo>? result]) {
  result ??= [];
  if (span is TextSpan) {
    if (span.text != null && span.text!.isNotEmpty) {
      result.add(_SpanInfo(text: span.text!, style: span.style));
    }
    if (span.children != null) {
      for (final child in span.children!) {
        _extractSpanInfo(child, result);
      }
    }
  } else if (span is WidgetSpan) {
    result.add(const _SpanInfo(text: '[widget]', style: null));
  }
  return result;
}
```

**Display per span:**

| Property | Source | Format |
|----------|--------|--------|
| Font family | `style.fontFamily` | string |
| Font size | `style.fontSize` | "14.0" |
| Weight | `style.fontWeight` | "FontWeight.w600" |
| Color | `style.color` | "#FF2196F3" + color preview square |
| Decoration | `style.decoration` | "TextDecoration.underline" |
| Height | `style.height` | "1.5" |
| Letter spacing | `style.letterSpacing` | "0.5" (only if non-null) |
| Word spacing | `style.wordSpacing` | "2.0" (only if non-null) |
| Font style | `style.fontStyle` | "italic" (only if non-null) |

**Multi-span:** если spans > 1, показать text preview первых 40 символов перед каждым стилем:
```
"Hello, world" (italic, 10pt)
  font: Roboto | size: 14.0 | weight: w400 | color: #FF000000
"Bold part" (italic, 10pt)
  font: Roboto | size: 14.0 | weight: w700 | color: #FF2196F3
```

#### 2. Box decoration inspection для `RenderDecoratedBox`

**Find в hit-test path** (не только target — Container оборачивает в alignment wrapper):
```dart
RenderDecoratedBox? _findDecoratedBox(BoxInfo boxInfo) {
  final target = boxInfo.targetRenderBox;
  if (target is RenderDecoratedBox && target.decoration is BoxDecoration) {
    return target;
  }
  // Fallback: search hit-test boxes
  for (final box in boxInfo.boxes) {
    if (box is RenderDecoratedBox && box.decoration is BoxDecoration) {
      return box;
    }
  }
  return null;
}
```

**Extract properties:**

| Property | Source | Format |
|----------|--------|--------|
| Border radius | `decoration.borderRadius` | "8.0, 8.0, 8.0, 8.0" (TL, TR, BR, BL) |
| Shape | `decoration.shape` | "circle" (only if != rectangle) |
| Color | `decoration.color` | "#FF2196F3" + color preview square |

**Format border radius:**
```dart
String _formatBorderRadius(BorderRadiusGeometry geometry) {
  final resolved = geometry.resolve(TextDirection.ltr);
  String f(double v) => v.toStringAsFixed(1);
  return '${f(resolved.topLeft.x)}, ${f(resolved.topRight.x)}, '
      '${f(resolved.bottomRight.x)}, ${f(resolved.bottomLeft.x)}';
}
```

### Чеклист

- [ ] `_RenderParagraphInfo` widget — detect RenderParagraph, extract spans
- [ ] `_extractSpanInfo()` — рекурсивный обход InlineSpan tree
- [ ] Single span → flat style row (font, size, weight, color, decoration, height)
- [ ] Multi-span → text preview + style row per span
- [ ] WidgetSpan → показать "[widget]"
- [ ] Optional properties (letterSpacing, wordSpacing, fontStyle) — показать только если non-null
- [ ] `_RenderDecoratedBoxInfo` widget — detect RenderDecoratedBox
- [ ] `_findDecoratedBox()` — поиск по target + boxes fallback
- [ ] Border radius в формате "TL, TR, BR, BL"
- [ ] Shape — показать только если не rectangle
- [ ] Color — hex + preview square
- [ ] `_formatBorderRadius()` utility
- [ ] `dart analyze --fatal-infos && dart test`

### Acceptance Criteria

1. Tap на `Text("Hello")` → панель показывает font family, size, weight, color
2. Tap на `RichText` с 3 spans → панель показывает 3 секции с preview и стилями
3. Tap на `Container(decoration: BoxDecoration(borderRadius: ...))` → панель показывает border radius и color
4. Tap на `Container(decoration: BoxDecoration(shape: BoxShape.circle))` → показывает "circle"
5. Decoration найдена даже если Container использует alignment wrapper (не прямой target)

**Референс:** `box_info_panel_widget.dart:374-619` (полная реализация text + decoration)

---

## Порядок PR'ов

```
PR #2 (Distance calculation) ─── базовый алгоритм
         │
         ▼
PR #3 (Visual lines) ────────── зависит от #2
         │
         ▼
PR #1 (Tap-tap compare) ─────── UX, логично после визуализации

PR #5 (Text + decoration) ────── независим, можно параллельно с #1-#3
PR #4 (Enhanced zoom) ────────── независим, самый большой по объему
```

1. **PR #2** — Distance calculation (data model + algorithm)
2. **PR #3** — Visual lines (CustomPainter, зависит от #2)
3. **PR #1** — Tap-tap compare (UX change)
4. **PR #5** — Text + decoration inspection (независим)
5. **PR #4** — Enhanced zoom (независим, самый большой)

---

## После мержа всех PR'ов

Когда все PR'ы приняты в inspector (предположительно `^5.0.0`):

### 1. Обновить зависимость

```yaml
# packages/ispect/pubspec.yaml
inspector: ^5.0.0  # было ^3.1.0
```

### 2. Удалить кастомный inspector код

Удалить всю директорию `packages/ispect/lib/src/features/inspector/src/`:
- `inspector.dart` (~740 строк)
- `inspector_builder.dart` (оставить, но переписать)
- `keyboard_handler.dart` (~134 строк)
- `utils.dart` (~164 строк)
- `inspector/box_info.dart` (~332 строк)
- `inspector/overlay.dart` (~110 строк)
- `widgets/components/box_info_widget.dart` (~124 строк)
- `widgets/components/box_info_panel_widget.dart` (~795 строк)
- `widgets/components/box_model_painter.dart` (~128 строк)
- `widgets/components/compare_overlay_painter.dart` (~180 строк)
- `widgets/components/information_box_widget.dart` (~58 строк)
- `widgets/components/overlay_painter.dart` (~52 строк)
- `widgets/color_picker/utils.dart` (~69 строк)
- `widgets/color_picker/color_picker_snackbar.dart` (~102 строк)
- `widgets/zoomable_color_picker/overlay.dart` (~272 строк)

**Итого:** ~3260 строк удалено

### 3. Переписать `inspector_builder.dart`

```dart
Inspector(
  controller: InspectorController(
    enableColorPicker: options.isColorPickerEnabled,
    enableInspect: options.isInspectorEnabled,
    enableCompare: true,
    enableZoom: true,
  ),
  panelBuilder: (controller) {
    return ListenableBuilder(
      listenable: controller.modeNotifier,
      child: child,
      builder: (context, child) => DraggablePanel(
        items: [
          if (options.isInspectorEnabled)
            DraggablePanelItem(
              icon: Icons.format_shapes,
              enableBadge: controller.modeNotifier.value == InspectorMode.inspector,
              onTap: (_) => controller.toggleInspector(),
            ),
          if (options.isColorPickerEnabled)
            DraggablePanelItem(
              icon: Icons.colorize,
              enableBadge: controller.modeNotifier.value == InspectorMode.colorPicker,
              onTap: (ctx) => controller.toggleColorPicker(),
            ),
          DraggablePanelItem(
            icon: Icons.zoom_in,
            enableBadge: controller.modeNotifier.value == InspectorMode.zoom,
            onTap: (_) => controller.toggleZoom(),
          ),
          // ... other ispect panel items (logs, performance, etc.)
        ],
        child: child,
      ),
    );
  },
  child: child,
)
```

### 4. Validate

```bash
cd packages/ispect && flutter analyze --fatal-infos && flutter test
```

---

## Промпт

```
Открой и выполни ТЗ из plans/inspector-contributions.md.
Это серия PR'ов в https://github.com/kekland/inspector для переноса
кастомных фич из ispect upstream. Референс-реализация лежит в
packages/ispect/lib/src/features/inspector/src/.
Клонируй inspector репо, изучи текущий код, и реализуй PR'ы
в порядке из ТЗ. После каждого — analyze + test.
```
