import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ispect_layout/src/inspector_controller.dart';
import 'package:ispect_layout/src/widgets/color_picker/utils.dart';

/// Floating Confirm / Cancel bar shown at the bottom of the screen while
/// [InspectorMode.colorPicker] or [InspectorMode.zoom] is active.
///
/// Replaces the legacy "tap-to-commit" gesture: tapping anywhere on the
/// surface only locks the sample, and the user explicitly resolves the mode
/// through this bar. In zoom mode it also exposes −/+ controls so users on
/// touch devices can change the loupe scale without a scroll wheel.
class InspectorActionsBar extends StatelessWidget {
  const InspectorActionsBar({super.key, required this.controller});

  final InspectorController controller;

  static const _supportedModes = <InspectorMode>{
    InspectorMode.colorPicker,
    InspectorMode.zoom,
  };

  /// Width below which button labels collapse to icon-only and the zoom
  /// stepper hides its numeric readout. Picked so the standard color picker
  /// layout still fits on a typical phone in portrait without wrapping.
  static const double _compactBreakpoint = 360.0;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<InspectorMode>(
      valueListenable: controller.modeNotifier,
      builder: (context, mode, _) {
        if (!_supportedModes.contains(mode)) return const SizedBox.shrink();

        return Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              bottom: 16.0,
            ),
            child: SafeArea(
              top: false,
              minimum: const EdgeInsets.only(bottom: 8.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < _compactBreakpoint;
                  return _ActionsRow(
                    mode: mode,
                    controller: controller,
                    isCompact: isCompact,
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ActionsRow extends StatelessWidget {
  const _ActionsRow({
    required this.mode,
    required this.controller,
    required this.isCompact,
  });

  final InspectorMode mode;
  final InspectorController controller;
  final bool isCompact;

  String get _confirmLabel {
    switch (mode) {
      case InspectorMode.colorPicker:
        return 'Select';
      case InspectorMode.zoom:
        return 'Done';
      case InspectorMode.inspector:
      case InspectorMode.inspectAndCompare:
      case InspectorMode.compareSelect:
      case InspectorMode.none:
        return 'Done';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(28.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 16.0,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.center,
          children: [
            _BarButton(
              label: 'Cancel',
              icon: Icons.close,
              onPressed: controller.cancelCurrentMode,
              isPrimary: false,
              showLabel: !isCompact,
            ),
            if (mode == InspectorMode.zoom || mode == InspectorMode.colorPicker)
              _ZoomStepperButtons(
                controller: controller,
                showValue: !isCompact,
              ),
            if (mode == InspectorMode.colorPicker)
              _ColorPreviewChip(
                controller: controller,
                isCompact: isCompact,
              ),
            _ConfirmButton(
              label: _confirmLabel,
              controller: controller,
              mode: mode,
              showLabel: !isCompact,
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  const _ConfirmButton({
    required this.label,
    required this.controller,
    required this.mode,
    required this.showLabel,
  });

  final String label;
  final InspectorController controller;
  final InspectorMode mode;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller.selectedColorStateNotifier,
      builder: (context, _) {
        final isEnabled = mode != InspectorMode.colorPicker ||
            controller.selectedColorStateNotifier.value != null;
        return _BarButton(
          label: label,
          icon: Icons.check,
          onPressed: isEnabled
              ? () => controller.confirmCurrentSelection(context: context)
              : null,
          isPrimary: true,
          showLabel: showLabel,
        );
      },
    );
  }
}

class _ZoomStepperButtons extends StatelessWidget {
  const _ZoomStepperButtons({
    required this.controller,
    required this.showValue,
  });

  final InspectorController controller;
  final bool showValue;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller.zoomScaleNotifier,
      builder: (context, _) {
        final scale = controller.zoomScaleNotifier.value;
        final canZoomOut = scale > controller.minZoomScale;
        final canZoomIn = scale < controller.maxZoomScale;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _BarIconButton(
              icon: Icons.remove,
              onPressed: canZoomOut ? controller.zoomOut : null,
              semanticLabel: 'Zoom out',
            ),
            if (showValue) ...[
              const SizedBox(width: 6.0),
              SizedBox(
                width: 36.0,
                child: Text(
                  '${scale.toStringAsFixed(0)}×',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.0,
                    fontWeight: FontWeight.w600,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(width: 6.0),
            ] else
              const SizedBox(width: 4.0),
            _BarIconButton(
              icon: Icons.add,
              onPressed: canZoomIn ? controller.zoomIn : null,
              semanticLabel: 'Zoom in',
            ),
          ],
        );
      },
    );
  }
}

class _ColorPreviewChip extends StatelessWidget {
  const _ColorPreviewChip({
    required this.controller,
    required this.isCompact,
  });

  final InspectorController controller;
  final bool isCompact;

  void _copyHex(BuildContext context, Color color) {
    final hex = colorToDisplayHex(color);
    Clipboard.setData(ClipboardData(text: hex));
    HapticFeedback.lightImpact();
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.clearSnackBars();
    messenger?.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        content: Text('Copied $hex'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller.selectedColorStateNotifier,
      builder: (context, _) {
        final color = controller.selectedColorStateNotifier.value;
        final hasColor = color != null;
        final hex = hasColor ? colorToDisplayHex(color) : '—';

        return Material(
          color: Colors.white.withValues(alpha: hasColor ? 0.12 : 0.06),
          borderRadius: BorderRadius.circular(20.0),
          child: InkWell(
            onTap: hasColor ? () => _copyHex(context, color) : null,
            borderRadius: BorderRadius.circular(20.0),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Swatch(color: color),
                  const SizedBox(width: 8.0),
                  Flexible(
                    child: Text(
                      hex,
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                      style: TextStyle(
                        color: hasColor ? Colors.white : Colors.white60,
                        fontSize: 13.0,
                        fontWeight: FontWeight.w600,
                        fontFamilyFallback: const ['Menlo', 'Courier'],
                        fontFeatures: const [FontFeature.tabularFigures()],
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  if (!isCompact) ...[
                    const SizedBox(width: 6.0),
                    Icon(
                      Icons.content_copy,
                      size: 14.0,
                      color: hasColor ? Colors.white70 : Colors.white38,
                      semanticLabel: 'Copy hex',
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18.0,
      height: 18.0,
      decoration: BoxDecoration(
        color: color ?? Colors.transparent,
        borderRadius: BorderRadius.circular(5.0),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.5),
          width: 1.0,
        ),
      ),
      child: color == null
          ? const Icon(
              Icons.colorize,
              size: 12.0,
              color: Colors.white60,
            )
          : null,
    );
  }
}

class _BarButton extends StatelessWidget {
  const _BarButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.isPrimary,
    this.showLabel = true,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;
    final background = isPrimary
        ? (isEnabled ? Colors.blue : Colors.blue.withValues(alpha: 0.4))
        : Colors.white.withValues(alpha: 0.12);
    final foreground =
        isPrimary ? Colors.white : (isEnabled ? Colors.white : Colors.white60);

    final padding = showLabel
        ? const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0)
        : const EdgeInsets.all(10.0);

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(20.0),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20.0),
        child: Padding(
          padding: padding,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18.0,
                color: foreground,
                semanticLabel: showLabel ? null : label,
              ),
              if (showLabel) ...[
                const SizedBox(width: 6.0),
                Text(
                  label,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 14.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BarIconButton extends StatelessWidget {
  const _BarIconButton({
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;
    return Material(
      color: Colors.white.withValues(alpha: isEnabled ? 0.12 : 0.06),
      borderRadius: BorderRadius.circular(20.0),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20.0),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(
            icon,
            size: 20.0,
            color: isEnabled ? Colors.white : Colors.white38,
            semanticLabel: semanticLabel,
          ),
        ),
      ),
    );
  }
}
