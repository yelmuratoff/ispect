import 'package:draggable_panel/draggable_panel.dart';
import 'package:flutter/widgets.dart';

/// The pieces ISpect assembles for the diagnostics panel, handed to an
/// [ISpectPanelBuilder] so consumers can return a fully customized panel
/// without ISpect forwarding each `draggable_panel` parameter individually.
@immutable
final class ISpectPanelData {
  const ISpectPanelData({
    required this.controller,
    required this.actions,
    required this.buttons,
    required this.theme,
    required this.actionTheme,
    required this.child,
  });

  /// The panel controller ISpect manages (or the one passed to `ISpectBuilder`).
  /// Pass it to `DraggableActionPanel.controller` so toggling and disposal stay
  /// wired.
  final DraggablePanelController controller;

  /// The assembled panel actions: built-in tools (log viewer, performance,
  /// inspector, color picker), `ISpectOptions.panelItems`, and plugin entries.
  final List<PanelAction> actions;

  /// The action buttons from `ISpectOptions.panelButtons`.
  final List<PanelActionButton> buttons;

  /// ISpect's resolved default panel theme. Use it as-is or as a `copyWith` base.
  final DraggablePanelThemeData theme;

  /// ISpect's resolved default action-grid theme. Use it as-is or as a
  /// `copyWith` base.
  final DraggableActionPanelThemeData actionTheme;

  /// The app content the panel floats over. Pass it to the panel's `child`.
  final Widget? child;
}

/// Builds the diagnostics panel from the pieces ISpect assembles.
///
/// Return a `DraggableActionPanel`, a bare `DraggablePanel` with your own
/// `collapsedBuilder`/`expandedBuilder`, or any widget that wraps
/// [ISpectPanelData.child] — every `draggable_panel` parameter (builders,
/// motion, behavior flags, placement, sizing), including ones added in future
/// `draggable_panel` releases, is available here without ISpect having to
/// forward each one.
typedef ISpectPanelBuilder =
    Widget Function(BuildContext context, ISpectPanelData data);
