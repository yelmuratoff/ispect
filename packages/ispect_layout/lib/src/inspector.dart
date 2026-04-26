import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ispect_layout/src/inspector_controller.dart';
import 'package:ispect_layout/src/theme.dart';
import 'package:ispect_layout/src/widgets/ignore_tap_gesture.dart';
import 'package:ispect_layout/src/widgets/zoom/zoom_overlay.dart';
import 'package:ispect_layout/src/widgets/zoomable_color_picker/zoomable_color_picker.dart';

import './widgets/panel/inspector_actions_bar.dart';
import './widgets/panel/inspector_panel.dart';
import 'widgets/inspector/overlay.dart';
import 'widgets/multi_value_listenable.dart';

/// [Inspector] can wrap any [child], and will display its control panel and
/// information overlay on top of that [child].
///
/// You should use [Inspector] as a wrapper to [WidgetsApp.builder] or
/// [MaterialApp.builder].
///
/// If [isEnabled] is [null], then [Inspector] is automatically disabled on
/// production builds (i.e. [kReleaseMode] is [true]).
///
/// [isPanelVisible] controls the visibility of the control panel - setting it
/// to [false] will hide the panel, but the other functionality can still be
/// accessed through keyboard shortcuts. If you want to disable the inspector
/// entirely, use [isEnabled]. [initialPanelExpanded] controls whether the
/// visible panel starts expanded or collapsed.
class Inspector extends StatefulWidget {
  const Inspector({
    super.key,
    required this.child,
    this.controller,
    this.alignment = Alignment.center,
    this.isPanelVisible = true,
    this.initialPanelExpanded = true,
    this.isEnabled,
    this.decimalPlaces = 1,
    this.theme,
    this.panelBuilder,
  }) : assert(decimalPlaces >= 0, 'decimalPlaces must be >= 0');

  final Widget child;
  final InspectorController? controller;
  final bool isPanelVisible;
  final bool initialPanelExpanded;
  final Alignment alignment;
  final bool? isEnabled;
  final int decimalPlaces;

  /// Overlay accent colours. When non-null and no [controller] is provided,
  /// this is forwarded to the internally-created [InspectorController].
  /// Ignored if [controller] is supplied (set it there instead).
  final InspectorTheme? theme;

  final Widget Function(
          BuildContext context, InspectorController controller, Widget child)?
      panelBuilder;

  @override
  InspectorState createState() => InspectorState();
}

class InspectorState extends State<Inspector> {
  bool _isPanelVisible = false;
  Size? _lastObservedSize;

  bool get isPanelVisible => _isPanelVisible;

  void togglePanelVisibility() =>
      setState(() => _isPanelVisible = !_isPanelVisible);

  late InspectorController _controller;
  InspectorController get controller => _controller;

  // Picker disc canvas size — image-only area; the visible disc is +40 px
  // wider on each axis because the rings are painted outside the canvas.
  // Tuned so the total visible disc lands roughly where the previous
  // in-canvas-rings version was (overlay ~128–246).
  static const double _overlayMinSize = 88;
  static const double _overlayMaxSize = 206;
  static const double _overlayOffsetY = 16;

  // Approximate HUD chip footprint and the gap it sits at from the disc.
  // Used to test fit-on-screen for each candidate placement.
  // Gap includes the +20 px ring stack drawn outside the disc canvas, so the
  // fit-test mirrors what _hudPositioned actually does in the overlay.
  static const double _hudWidth = 168;
  static const double _hudHeight = 32;
  static const double _hudAxialGap = 16 + 20;
  static const double _hudLateralGap = 12 + 20;

  // Vertical space at the bottom of the screen reserved for the floating
  // action bar (button + paddings); HUD-below should not overlap it.
  static const double _hudBottomReserved = 96;
  static const _enterInspectorIntent = _EnterInspectorIntent();
  static const _enterColorPickerIntent = _EnterColorPickerIntent();
  static const _toggleCompareIntent = _ToggleCompareIntent();
  static const _enterZoomIntent = _EnterZoomIntent();

  @override
  void initState() {
    _isPanelVisible = widget.isPanelVisible;
    super.initState();

    _controller = widget.controller ??
        InspectorController(
          isEnabled: _isEnabled,
          decimalPlaces: widget.decimalPlaces,
          theme: widget.theme ?? InspectorTheme.defaults,
        );
  }

  @override
  void didUpdateWidget(covariant Inspector oldWidget) {
    super.didUpdateWidget(oldWidget);

    final controllerChanged = oldWidget.controller != widget.controller;
    final isEnabledChanged = oldWidget.isEnabled != widget.isEnabled;
    final decimalPlacesChanged =
        oldWidget.decimalPlaces != widget.decimalPlaces &&
            widget.controller == null;

    if (controllerChanged || isEnabledChanged || decimalPlacesChanged) {
      // Dispose the previous controller only if we owned it (created
      // internally). A user-supplied controller must be disposed by the user.
      if (oldWidget.controller == null) {
        _controller.dispose();
      }
      _controller = widget.controller ??
          InspectorController(
            isEnabled: _isEnabled,
            decimalPlaces: widget.decimalPlaces,
          );
    }

    if (widget.isPanelVisible != oldWidget.isPanelVisible) {
      _isPanelVisible = widget.isPanelVisible;
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  /// Re-captures the pixel snapshot when the surface the picker / loupe is
  /// sampling from gets resized. Without this, on desktop / web the cached
  /// image is taken once at mode entry and the loupe keeps showing stale
  /// pixels at stale positions after a window resize or orientation change.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final size = MediaQuery.maybeSizeOf(context);
    if (size == null) return;
    final previous = _lastObservedSize;
    _lastObservedSize = size;
    if (previous != null && previous != size) {
      _controller.invalidateCapturedImage();
    }
  }

  /// The inspector is enabled if:
  /// 1. [widget.isEnabled] is [null] and we're running in debug mode, or
  /// 2. [widget.isEnabled] is [true]
  bool get _isEnabled =>
      (widget.isEnabled == null && !kReleaseMode) ||
      (widget.isEnabled != null && widget.isEnabled!);

  @override
  Widget build(BuildContext context) {
    if (!_isEnabled) {
      return widget.child;
    }

    final content = Stack(
      key: _controller.stackKey,
      children: [
        Align(
          alignment: widget.alignment,
          child: ValueListenableBuilder<InspectorMode>(
            valueListenable: _controller.modeNotifier,
            builder: (context, mode, _) {
              Widget child = widget.child;

              final isIgnoringPointer = mode != InspectorMode.none;

              return MouseRegion(
                onExit: (e) => _controller.onPointerExit(e.position),
                child: Listener(
                  behavior: HitTestBehavior.translucent,
                  onPointerUp: (e) => _controller.onTap(e.position, context),
                  onPointerMove: (e) =>
                      _controller.onPointerMove(e.position, context),
                  onPointerDown: (e) =>
                      _controller.onPointerMove(e.position, context),
                  onPointerHover: (e) =>
                      _controller.onPointerHoverDebounced(e.position, context),
                  onPointerSignal: (event) {
                    if (event is PointerScrollEvent) {
                      _controller.onPointerScroll(event);
                    }
                  },
                  child: RepaintBoundary(
                    key: controller.repaintBoundaryKey,
                    child: Stack(
                      children: [
                        KeyedSubtree(
                          key: controller.ignoringPointerKey,
                          child: child,
                        ),
                        if (isIgnoringPointer)
                          const Positioned.fill(
                            child: IgnoreTapGesture(),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        MultiValueListenableBuilder(
          valueListenables: [
            _controller.modeNotifier,
            _controller.selectedColorOffsetNotifier,
            _controller.selectedColorStateNotifier,
            _controller.selectedColorImageOffsetNotifier,
            _controller.byteDataStateNotifier,
            _controller.zoomScaleNotifier,
          ],
          builder: (context) {
            final mode = _controller.modeNotifier.value;
            if (mode != InspectorMode.colorPicker) {
              return const SizedBox.shrink();
            }

            final offset = _controller.selectedColorOffsetNotifier.value;
            final color = _controller.selectedColorStateNotifier.value;
            final image = _controller.image;
            final zoomScale = _controller.zoomScaleNotifier.value;
            final screenSize = MediaQuery.sizeOf(context);
            final overlaySize = ui.lerpDouble(
              _overlayMinSize,
              _overlayMaxSize,
              ((zoomScale - 2.0) / 10.0).clamp(0, 1),
            )!;

            // Image can be null briefly after a window resize / orientation
            // change while the snapshot is being re-captured. Bail until the
            // next frame rather than dereferencing it.
            if (offset == null || color == null || image == null) {
              return const SizedBox.shrink();
            }

            final pickerLeft =
                offset.dx.clamp(0.0, screenSize.width - overlaySize);
            final pickerTop = (offset.dy - overlaySize - _overlayOffsetY)
                .clamp(0.0, screenSize.height - overlaySize);

            // Pick the side of the disc where the HUD chip fully fits in
            // the on-screen bounds (minus the bottom action-bar / safe area).
            // Priority: above (default) → right → left → below — "below" is
            // last because the user's finger lives there.
            final placement = _resolveHudPlacement(
              pickerLeft: pickerLeft,
              pickerTop: pickerTop,
              overlaySize: overlaySize,
              screenSize: screenSize,
              bottomReserved:
                  MediaQuery.paddingOf(context).bottom + _hudBottomReserved,
            );

            return Positioned(
              left: pickerLeft,
              top: pickerTop,
              child: ZoomableColorPickerOverlay(
                color: color,
                image: image,
                imageOffset:
                    _controller.selectedColorImageOffsetNotifier.value ??
                        Offset.zero,
                overlaySize: overlaySize,
                zoomScale: zoomScale,
                pixelRatio: MediaQuery.devicePixelRatioOf(context),
                hudPlacement: placement,
              ),
            );
          },
        ),
        MultiValueListenableBuilder(
          valueListenables: [
            _controller.modeNotifier,
            _controller.currentRenderBoxNotifier,
            _controller.hoveredRenderBoxNotifier,
            _controller.comparedRenderBoxNotifier,
          ],
          builder: (context) {
            final mode = _controller.modeNotifier.value;
            if (mode != InspectorMode.inspector &&
                mode != InspectorMode.inspectAndCompare &&
                mode != InspectorMode.compareSelect) {
              return const SizedBox.shrink();
            }

            final isCompareActive = mode == InspectorMode.compareSelect;
            final onCompare = _controller.isWidgetInspectAndCompareEnabled
                ? (isCompareActive
                    ? _controller.exitCompareMode
                    : _controller.enterCompareMode)
                : null;

            return LayoutBuilder(
              builder: (context, constraints) => InspectorOverlay(
                size: constraints.biggest,
                boxInfo: _controller.currentRenderBoxNotifier.value,
                hoveredBoxInfo: _controller.hoveredRenderBoxNotifier.value,
                comparedBoxInfo: _controller.comparedRenderBoxNotifier.value,
                onCompare: onCompare,
                isCompareActive: isCompareActive,
                decimalPlaces: _controller.decimalPlaces,
                theme: _controller.theme,
              ),
            );
          },
        ),
        MultiValueListenableBuilder(
          valueListenables: [
            _controller.modeNotifier,
            _controller.zoomImageOffsetNotifier,
            _controller.zoomOverlayOffsetNotifier,
            _controller.byteDataStateNotifier,
            _controller.zoomScaleNotifier,
          ],
          builder: (context) {
            final mode = _controller.modeNotifier.value;
            if (mode != InspectorMode.zoom) return const SizedBox.shrink();

            final offset = _controller.zoomOverlayOffsetNotifier.value;
            final imageOffset = _controller.zoomImageOffsetNotifier.value;
            final byteData = _controller.byteDataStateNotifier.value;
            final zoomScale = _controller.zoomScaleNotifier.value;

            if (offset == null || byteData == null || imageOffset == null) {
              return const SizedBox.shrink();
            }

            final overlaySize = ui
                .lerpDouble(
                  128.0,
                  256.0,
                  ((zoomScale - 2.0) / 10.0).clamp(0, 1),
                )!
                .toDouble();
            final screenSize = MediaQuery.sizeOf(context);
            final left = (offset.dx - overlaySize / 2)
                .clamp(0.0, screenSize.width - overlaySize);
            final top = (offset.dy - overlaySize / 2)
                .clamp(0.0, screenSize.height - overlaySize);

            return Positioned(
              left: left,
              top: top,
              child: IgnorePointer(
                child: ZoomOverlayWidget(
                  image: _controller.image!,
                  imageOffset: imageOffset,
                  overlaySize: overlaySize,
                  zoomScale: zoomScale,
                  pixelRatio: MediaQuery.of(context).devicePixelRatio,
                ),
              ),
            );
          },
        ),
        InspectorActionsBar(controller: _controller),
      ],
    );

    final keyboardAwareContent = Shortcuts(
      shortcuts: _buildShortcuts(),
      child: Actions(
        actions: {
          _EnterInspectorIntent: CallbackAction<_EnterInspectorIntent>(
            onInvoke: (_) {
              _controller.handleInspectorShortcut(true);
              return null;
            },
          ),
          _EnterColorPickerIntent: CallbackAction<_EnterColorPickerIntent>(
            onInvoke: (_) {
              _controller.handleColorPickerShortcut(true);
              return null;
            },
          ),
          _ToggleCompareIntent: CallbackAction<_ToggleCompareIntent>(
            onInvoke: (_) {
              _controller.handleCompareShortcut();
              return null;
            },
          ),
          _EnterZoomIntent: CallbackAction<_EnterZoomIntent>(
            onInvoke: (_) {
              _controller.handleZoomShortcut(true);
              return null;
            },
          ),
        },
        // Not autofocus — the inspector should never steal focus from
        // TextFields or other interactive descendants. Shortcuts still fire
        // as long as the focus tree includes this node, which it always does
        // (the Focus sits above the whole app tree).
        child: Focus(
          onKeyEvent: _handleKeyEvent,
          child: content,
        ),
      ),
    );

    if (widget.panelBuilder != null) {
      return widget.panelBuilder!(context, _controller, keyboardAwareContent);
    }

    return Stack(
      children: [
        keyboardAwareContent,
        if (_isPanelVisible)
          Align(
            alignment: Alignment.centerRight,
            // InspectorPanel subscribes to modeNotifier internally.
            child: InspectorPanel(
              controller: _controller,
              initialIsVisible: widget.initialPanelExpanded,
            ),
          ),
      ],
    );
  }

  /// Picks the first placement (in priority order) where the HUD chip's full
  /// bounding box is on-screen. Falls back to [HudPlacement.above] if no
  /// side fits — the chip will clip, but at least one fixed side is chosen
  /// (rather than disappearing) so the user can still nudge the picker.
  HudPlacement _resolveHudPlacement({
    required double pickerLeft,
    required double pickerTop,
    required double overlaySize,
    required Size screenSize,
    required double bottomReserved,
  }) {
    final bottomLimit = screenSize.height - bottomReserved;
    final centerX = pickerLeft + overlaySize / 2;
    final centerY = pickerTop + overlaySize / 2;

    bool fitsHorizontally(double centerX) {
      final left = centerX - _hudWidth / 2;
      return left >= 0 && left + _hudWidth <= screenSize.width;
    }

    bool fitsVertically(double centerY) {
      final top = centerY - _hudHeight / 2;
      return top >= 0 && top + _hudHeight <= bottomLimit;
    }

    final fitsAbove =
        pickerTop - _hudAxialGap - _hudHeight >= 0 && fitsHorizontally(centerX);
    final fitsBelow =
        pickerTop + overlaySize + _hudAxialGap + _hudHeight <= bottomLimit &&
            fitsHorizontally(centerX);
    final fitsRight = pickerLeft + overlaySize + _hudLateralGap + _hudWidth <=
            screenSize.width &&
        fitsVertically(centerY);
    final fitsLeft =
        pickerLeft - _hudLateralGap - _hudWidth >= 0 && fitsVertically(centerY);

    if (fitsAbove) return HudPlacement.above;
    if (fitsRight) return HudPlacement.right;
    if (fitsLeft) return HudPlacement.left;
    if (fitsBelow) return HudPlacement.below;
    return HudPlacement.above;
  }

  Map<ShortcutActivator, Intent> _buildShortcuts() {
    final shortcuts = <ShortcutActivator, Intent>{};

    for (final activator
        in _controller.effectiveWidgetInspectorShortcutActivators) {
      shortcuts.putIfAbsent(activator, () => _enterInspectorIntent);
    }

    for (final activator
        in _controller.effectiveWidgetInspectAndCompareShortcutActivators) {
      shortcuts.putIfAbsent(activator, () => _toggleCompareIntent);
    }

    for (final activator
        in _controller.effectiveColorPickerShortcutActivators) {
      shortcuts.putIfAbsent(activator, () => _enterColorPickerIntent);
    }

    for (final activator in _controller.effectiveZoomShortcutActivators) {
      shortcuts.putIfAbsent(activator, () => _enterZoomIntent);
    }

    return shortcuts;
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    final state = HardwareKeyboard.instance;

    if (_controller.acceptsWidgetInspectorShortcut(event, state) ||
        _controller.acceptsCompareShortcut(event, state) ||
        _controller.acceptsColorPickerShortcut(event, state) ||
        _controller.acceptsZoomShortcut(event, state)) {
      return KeyEventResult.ignored;
    }

    if (_shouldReleaseInspectorShortcut(event, state)) {
      _controller.handleInspectorShortcut(false);
      return KeyEventResult.handled;
    }

    if (_shouldReleaseColorPickerShortcut(event, state)) {
      _controller.handleColorPickerShortcut(false);
      return KeyEventResult.handled;
    }

    if (_shouldReleaseZoomShortcut(event, state)) {
      _controller.handleZoomShortcut(false);
      return KeyEventResult.handled;
    }

    if (_isRepeatFromShortcut(event, state)) {
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  bool _shouldReleaseInspectorShortcut(
          KeyEvent event, HardwareKeyboard state) =>
      event is KeyUpEvent &&
      _controller.modeNotifier.value == InspectorMode.inspector &&
      !_controller.isWidgetInspectorShortcutStillPressed(state);

  bool _shouldReleaseColorPickerShortcut(
          KeyEvent event, HardwareKeyboard state) =>
      event is KeyUpEvent &&
      _controller.modeNotifier.value == InspectorMode.colorPicker &&
      !_controller.isColorPickerShortcutStillPressed(state);

  bool _shouldReleaseZoomShortcut(KeyEvent event, HardwareKeyboard state) =>
      event is KeyUpEvent &&
      _controller.modeNotifier.value == InspectorMode.zoom &&
      !_controller.isZoomShortcutStillPressed(state);

  bool _isRepeatFromShortcut(KeyEvent event, HardwareKeyboard state) =>
      event is KeyRepeatEvent &&
      ((_controller.modeNotifier.value == InspectorMode.inspector &&
              _controller.isWidgetInspectorShortcutStillPressed(state)) ||
          (_controller.modeNotifier.value == InspectorMode.colorPicker &&
              _controller.isColorPickerShortcutStillPressed(state)) ||
          (_controller.modeNotifier.value == InspectorMode.zoom &&
              _controller.isZoomShortcutStillPressed(state)) ||
          _controller.acceptsCompareShortcut(event, state));
}

class _EnterInspectorIntent extends Intent {
  const _EnterInspectorIntent();
}

class _EnterColorPickerIntent extends Intent {
  const _EnterColorPickerIntent();
}

class _ToggleCompareIntent extends Intent {
  const _ToggleCompareIntent();
}

class _EnterZoomIntent extends Intent {
  const _EnterZoomIntent();
}
