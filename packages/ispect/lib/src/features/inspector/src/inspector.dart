// ignore_for_file: comment_references, avoid_public_members_in_states

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/controllers/draggable_button_controller.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/features/inspector/src/inspector/box_info.dart';
import 'package:ispect/src/features/inspector/src/inspector/overlay.dart';
import 'package:ispect/src/features/inspector/src/keyboard_handler.dart';
import 'package:ispect/src/features/inspector/src/utils.dart';
import 'package:ispect/src/features/inspector/src/widgets/color_picker/color_picker_snackbar.dart';
import 'package:ispect/src/features/inspector/src/widgets/color_picker/utils.dart';
import 'package:ispect/src/features/inspector/src/widgets/zoomable_color_picker/overlay.dart';
import 'package:ispect/src/features/ispect/presentation/screens/logs_screen.dart';

/// `Inspector` can wrap any [child], and will display its control panel and
/// information overlay on top of that `child`.
///
/// You should use `Inspector` as a wrapper to [WidgetsApp.builder] or
/// `MaterialApp.builder`.
///
/// If `isEnabled` is `null`, then [Inspector] is automatically disabled on
/// production builds (i.e. `kReleaseMode` is `true`).
///
/// You can disable the widget inspector or the color picker by passing `false`
/// to either `isWidgetInspectorEnabled` or [isColorPickerEnabled].
///
/// There are also keyboard shortcuts for the widget inspector and the color
/// picker. By default, pressing **Shift** will enable the color picker, and
/// pressing **Command** or **Alt** will enable the widget inspector. Those
/// shortcuts can be changed through `widgetInspectorShortcuts` and
/// `colorPickerShortcuts`.
///
/// `isPanelVisible` controls the visibility of the control panel - setting it
/// to `false` will hide the panel, but the other functionality can still be
/// accessed through keyboard shortcuts. If you want to disable the inspector
/// entirely, use `isEnabled`.
class Inspector extends StatefulWidget {
  const Inspector({
    required this.child,
    super.key,
    this.backgroundColor,
    this.textColor,
    this.selectedColor,
    this.selectedTextColor,
    this.alignment = Alignment.center,
    this.areKeyboardShortcutsEnabled = true,
    this.isPanelVisible = true,
    this.controller,
    this.widgetInspectorShortcuts = const [
      LogicalKeyboardKey.alt,
      LogicalKeyboardKey.altLeft,
      LogicalKeyboardKey.altRight,
      LogicalKeyboardKey.meta,
      LogicalKeyboardKey.metaLeft,
      LogicalKeyboardKey.metaRight,
    ],
    this.colorPickerShortcuts = const [
      LogicalKeyboardKey.shift,
      LogicalKeyboardKey.shiftLeft,
      LogicalKeyboardKey.shiftRight,
    ],
    this.zoomShortcuts = const [
      LogicalKeyboardKey.keyZ,
    ],
    this.isEnabled,
  });

  final Widget child;
  final bool areKeyboardShortcutsEnabled;
  final bool isPanelVisible;

  final Alignment alignment;
  final List<LogicalKeyboardKey> widgetInspectorShortcuts;
  final List<LogicalKeyboardKey> colorPickerShortcuts;
  final List<LogicalKeyboardKey> zoomShortcuts;
  final bool? isEnabled;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? selectedColor;
  final Color? selectedTextColor;

  final DraggablePanelController? controller;

  static InspectorState of(BuildContext context) {
    final result = maybeOf(context);
    if (result != null) {
      return result;
    }
    throw FlutterError.fromParts([
      ErrorSummary(
        'Inspector.of() error.',
      ),
      context.describeElement('the context'),
    ]);
  }

  static InspectorState? maybeOf(BuildContext? context) =>
      context?.findAncestorStateOfType<InspectorState>();

  @override
  InspectorState createState() => InspectorState();
}

class InspectorState extends State<Inspector> {
  static const double _defaultZoomScale = 3;
  static const double _minZoomScale = 1;
  static const double _maxZoomScale = 20;
  static const double _zoomStep = 1;
  static const double _overlayMinSize = 128;
  static const double _overlayMaxSize = 246;
  static const double _overlayOffsetY = 16;

  bool _isPanelVisible = false;
  bool get isPanelVisible => _isPanelVisible;

  void togglePanelVisibility() =>
      setState(() => _isPanelVisible = !_isPanelVisible);

  final _stackKey = GlobalKey();
  final _repaintBoundaryKey = GlobalKey();
  final _absorbPointerKey = GlobalKey();
  ui.Image? _image;

  final _byteDataStateNotifier = ValueNotifier<ByteData?>(null);

  final _currentRenderBoxNotifier = ValueNotifier<BoxInfo?>(null);

  final _inspectorStateNotifier = ValueNotifier<bool>(false);
  final _zoomStateNotifier = ValueNotifier<bool>(false);

  final _zoomImageOffsetNotifier = ValueNotifier<Offset?>(null);
  final _zoomScaleNotifier = ValueNotifier<double>(_defaultZoomScale);
  final _zoomOverlayOffsetNotifier = ValueNotifier<Offset?>(null);

  late final KeyboardHandler _keyboardHandler;

  Offset? _pointerHoverPosition;

  final _controller = InspectorController();
  late final DraggablePanelController _draggablePanelController;
  late final Listenable _panelListenable;

  @override
  void initState() {
    super.initState();

    // Validate zoom scale boundaries
    assert(
      _minZoomScale <= _defaultZoomScale && _defaultZoomScale <= _maxZoomScale,
      'Invalid zoom scale configuration: '
      'minZoom ($_minZoomScale) <= defaultZoom ($_defaultZoomScale) <= maxZoom ($_maxZoomScale)',
    );

    _draggablePanelController = widget.controller ?? DraggablePanelController();
    _isPanelVisible = widget.isPanelVisible;

    _keyboardHandler = KeyboardHandler(
      onInspectorStateChanged: ({required value}) {
        _onInspectorStateChanged(value);
      },
      onZoomStateChanged: ({required value}) {
        _onZoomStateChanged(value);
      },
      inspectorStateKeys: widget.widgetInspectorShortcuts,
      zoomStateKeys: widget.zoomShortcuts,
    );

    if (_isPanelVisible && widget.areKeyboardShortcutsEnabled) {
      _keyboardHandler.register();
    }

    // Merge panel-affecting listenables to avoid nested builders and
    // minimize rebuild overhead.
    _panelListenable = Listenable.merge([
      _controller,
      _inspectorStateNotifier,
      _zoomStateNotifier,
      _byteDataStateNotifier,
    ]);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.iSpect.options.observer != null) {
        ISpect.read(context).observer = context.iSpect.options.observer;
      }
    });
  }

  // Gestures

  void _onTap(Offset? pointerOffset) {
    if (_zoomStateNotifier.value) {
      _onZoomStateChanged(false);
      return;
    }

    if (!_inspectorStateNotifier.value) {
      return;
    }

    if (pointerOffset == null) return;

    final boxes = InspectorUtils.onTap(
      _absorbPointerKey.currentContext!,
      pointerOffset,
    );

    if (boxes.isEmpty) return;

    final overlayOffset =
        (_stackKey.currentContext!.findRenderObject()! as RenderStack)
            .localToGlobal(Offset.zero);

    _currentRenderBoxNotifier.value = BoxInfo.fromHitTestResults(
      boxes,
      overlayOffset: overlayOffset,
    );
  }

  void _onPointerMove(Offset pointerOffset) {
    _updatePointerPosition(pointerOffset);
  }

  void _onPointerHover(Offset pointerOffset) {
    _updatePointerPosition(pointerOffset);
  }

  void _updatePointerPosition(Offset pointerOffset) {
    _pointerHoverPosition = pointerOffset;
    if (_zoomStateNotifier.value) {
      _onZoomHover(pointerOffset);
    }
  }

  // Inspector

  void _onInspectorStateChanged(bool isEnabled) {
    if (!context.iSpect.options.isInspectorEnabled) {
      _inspectorStateNotifier.value = false;
      return;
    }

    _inspectorStateNotifier.value = isEnabled;

    if (isEnabled) {
      _onZoomStateChanged(false);
    } else {
      _currentRenderBoxNotifier.value = null;
    }
  }

  // Zoom

  void _onZoomStateChanged(bool isEnabled) {
    if (!context.iSpect.options.isColorPickerEnabled) {
      _zoomStateNotifier.value = false;
      return;
    }

    _zoomStateNotifier.value = isEnabled;

    if (isEnabled) {
      _onInspectorStateChanged(false);
      _zoomScaleNotifier.value = _defaultZoomScale;

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _extractByteData();

        if (_pointerHoverPosition != null) {
          _onZoomHover(_pointerHoverPosition!);
        }
      });
    } else {
      _handleZoomDisabled();
    }
  }

  void _handleZoomDisabled() {
    try {
      if (_byteDataStateNotifier.value != null) {
        final color = getPixelFromByteData(
          _byteDataStateNotifier.value!,
          width: _image!.width,
          x: _zoomImageOffsetNotifier.value!.dx.round(),
          y: _zoomImageOffsetNotifier.value!.dy.round(),
        );

        showColorPickerResultSnackbar(
          context: context,
          color: color,
        );
      }
    } finally {
      // Always clean up resources, even if an exception occurs
      _resetZoomState();
    }
  }

  void _resetZoomState() {
    _image?.dispose();
    _image = null;
    _byteDataStateNotifier.value = null;
    _zoomImageOffsetNotifier.value = null;
    _zoomOverlayOffsetNotifier.value = null;
    _zoomScaleNotifier.value = _defaultZoomScale;
  }

  Future<void> _extractByteData() async {
    if (_image != null) return;
    final boundary = _repaintBoundaryKey.currentContext!.findRenderObject()!
        as RenderRepaintBoundary;

    final pixelRatio = MediaQuery.devicePixelRatioOf(context);

    _image = await boundary.toImage(pixelRatio: pixelRatio);
    _byteDataStateNotifier.value = await _image!.toByteData();
  }

  Offset _extractShiftedOffset(Offset offset) {
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);

    var offset0 = (_repaintBoundaryKey.currentContext!.findRenderObject()!
            as RenderRepaintBoundary)
        .globalToLocal(offset);

    // ignore: join_return_with_assignment
    offset0 *= pixelRatio;

    return offset0;
  }

  void _onZoomHover(Offset offset) {
    if (_image == null || _byteDataStateNotifier.value == null) return;

    final shiftedOffset = _extractShiftedOffset(offset);

    final overlayOffset =
        (_stackKey.currentContext!.findRenderObject()! as RenderStack)
            .localToGlobal(Offset.zero);

    _zoomImageOffsetNotifier.value = shiftedOffset;
    _zoomOverlayOffsetNotifier.value = offset - overlayOffset;
  }

  void _onPointerScroll(PointerScrollEvent scrollEvent) {
    if (!_zoomStateNotifier.value) return;

    final scrollDirection = -scrollEvent.scrollDelta.dy.sign;
    final newValue = (_zoomScaleNotifier.value + _zoomStep * scrollDirection)
        .clamp(_minZoomScale, _maxZoomScale);

    if (newValue != _zoomScaleNotifier.value) {
      _zoomScaleNotifier.value = newValue;
    }
  }

  @override
  void didUpdateWidget(covariant Inspector oldWidget) {
    if (oldWidget.isEnabled != widget.isEnabled) {
      if (_isPanelVisible && widget.areKeyboardShortcutsEnabled) {
        _keyboardHandler.register();
      } else {
        _keyboardHandler.dispose();
      }
    }

    super.didUpdateWidget(oldWidget);

    if (widget.isPanelVisible != oldWidget.isPanelVisible) {
      _isPanelVisible = widget.isPanelVisible;
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _draggablePanelController.dispose();
    }
    _zoomOverlayOffsetNotifier.dispose();
    _zoomScaleNotifier.dispose();
    _zoomImageOffsetNotifier.dispose();
    _zoomStateNotifier.dispose();
    _inspectorStateNotifier.dispose();
    _currentRenderBoxNotifier.dispose();
    _byteDataStateNotifier.dispose();
    _image?.dispose();
    _byteDataStateNotifier.value = null;
    _keyboardHandler.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isPanelVisible) {
      return widget.child;
    }

    final iSpect = ISpect.read(context);
    final screenSize = MediaQuery.sizeOf(context);

    return Stack(
      key: _stackKey,
      children: [
        Align(
          alignment: widget.alignment,
          child: _buildMainChild(),
        ),
        _buildInspectorOverlay(),
        _buildColorPickerOverlay(screenSize),
        if (_isPanelVisible)
          AnimatedBuilder(
            animation: _panelListenable,
            builder: (context, __) => DraggablePanel(
              borderRadius: const BorderRadius.all(Radius.circular(16)),
              backgroundColor: context.isDarkMode
                  ? context.ispectTheme.colorScheme.primaryContainer
                  : context.ispectTheme.colorScheme.primary,
              controller: _draggablePanelController,
              items: [
                if (context.iSpect.options.isLogPageEnabled)
                  DraggablePanelItem(
                    icon: _controller.inLoggerPage
                        ? Icons.undo_rounded
                        : Icons.reorder_rounded,
                    enableBadge: _controller.inLoggerPage,
                    onTap: (_) {
                      _launchInfospect(context);
                    },
                    description: _controller.inLoggerPage
                        ? context.ispectL10n.backToMainScreen
                        : context.ispectL10n.openLogViewer,
                  ),
                if (context.iSpect.options.isPerformanceEnabled)
                  DraggablePanelItem(
                    icon: Icons.monitor_heart_outlined,
                    enableBadge: iSpect.isPerformanceTrackingEnabled,
                    onTap: (_) {
                      iSpect.togglePerformanceTracking();
                    },
                    description: context.ispectL10n.togglePerformanceTracking,
                  ),
                if (context.iSpect.options.isInspectorEnabled)
                  DraggablePanelItem(
                    icon: Icons.format_shapes_rounded,
                    enableBadge: _inspectorStateNotifier.value,
                    onTap: (_) {
                      _onInspectorStateChanged(
                        !_inspectorStateNotifier.value,
                      );
                    },
                    description: context.ispectL10n.inspectWidgets,
                  ),
                if (context.iSpect.options.isColorPickerEnabled)
                  DraggablePanelItem(
                    icon: Icons.colorize_rounded,
                    enableBadge: _zoomStateNotifier.value,
                    onTap: (_) {
                      _onZoomStateChanged(!_zoomStateNotifier.value);
                    },
                    description: context.ispectL10n.zoomPickColor,
                  ),
                ...context.iSpect.options.panelItems,
              ],
              buttons: context.iSpect.options.panelButtons,
              child: null,
            ),
          ),
      ],
    );
  }

  Widget _buildMainChild() => MultiValueListenableBuilder(
        valueListenables: [
          _inspectorStateNotifier,
          _zoomStateNotifier,
        ],
        builder: (_) {
          final isAbsorbingPointer =
              _inspectorStateNotifier.value || _zoomStateNotifier.value;

          return Listener(
            behavior: HitTestBehavior.translucent,
            onPointerUp: (e) => _onTap(e.position),
            onPointerMove: (e) => _onPointerMove(e.position),
            onPointerDown: (e) => _onPointerMove(e.position),
            onPointerHover: (e) => _onPointerHover(e.position),
            onPointerSignal: (event) {
              if (event is PointerScrollEvent) {
                _onPointerScroll(event);
              }
            },
            child: RepaintBoundary(
              key: _repaintBoundaryKey,
              child: AbsorbPointer(
                key: _absorbPointerKey,
                absorbing: isAbsorbingPointer,
                child: widget.child,
              ),
            ),
          );
        },
      );

  Widget _buildInspectorOverlay() {
    if (!context.iSpect.options.isInspectorEnabled) {
      return const SizedBox.shrink();
    }

    return MultiValueListenableBuilder(
      valueListenables: [
        _currentRenderBoxNotifier,
        _inspectorStateNotifier,
        _zoomStateNotifier,
      ],
      builder: (_) => LayoutBuilder(
        key: const ValueKey('inspector_overlay_layout_builder'),
        builder: (_, constraints) => _inspectorStateNotifier.value
            ? InspectorOverlay(
                size: constraints.biggest,
                boxInfo: _currentRenderBoxNotifier.value,
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildColorPickerOverlay(Size screenSize) {
    if (!context.iSpect.options.isColorPickerEnabled) {
      return const SizedBox.shrink();
    }

    return MultiValueListenableBuilder(
      valueListenables: [
        _zoomImageOffsetNotifier,
        _zoomOverlayOffsetNotifier,
        _byteDataStateNotifier,
        _zoomScaleNotifier,
      ],
      builder: (context) {
        final offset = _zoomOverlayOffsetNotifier.value;
        final imageOffset = _zoomImageOffsetNotifier.value;
        final byteData = _byteDataStateNotifier.value;
        final zoomScale = _zoomScaleNotifier.value;

        if (offset == null || byteData == null || imageOffset == null) {
          return const SizedBox.shrink();
        }

        final overlaySize = ui.lerpDouble(
          _overlayMinSize,
          _overlayMaxSize,
          ((zoomScale - 2.0) / 10.0).clamp(0, 1),
        )!;

        return Positioned(
          left: offset.dx.clamp(0, screenSize.width - overlaySize),
          top: (offset.dy - overlaySize - _overlayOffsetY)
              .clamp(0, screenSize.height),
          child: IgnorePointer(
            child: CombinedOverlayWidget(
              image: _image!,
              overlayOffset: offset,
              imageOffset: imageOffset,
              overlaySize: overlaySize,
              zoomScale: zoomScale,
              pixelRatio: MediaQuery.devicePixelRatioOf(context),
              color: getPixelFromByteData(
                byteData,
                width: _image!.width,
                x: imageOffset.dx.round(),
                y: imageOffset.dy.round(),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _launchInfospect(BuildContext context) async {
    final iSpect = ISpect.read(context);
    final iSpectScreen = MaterialPageRoute<dynamic>(
      builder: (_) => LogsScreen(
        options: context.iSpect.options,
        appBarTitle: iSpect.theme.pageTitle,
        itemsBuilder: context.iSpect.options.itemsBuilder,
      ),
      settings: const RouteSettings(
        name: 'ISpect Screen',
      ),
    );
    if (_controller.inLoggerPage) {
      context.iSpect.options.pop(context);
    } else {
      _controller.setInLoggerPage(isLoggerPage: true);

      await context.iSpect.options.push(context, iSpectScreen).then((_) {
        if (context.mounted) {
          _controller.setInLoggerPage(isLoggerPage: false);
        }
      });
    }
  }
}
