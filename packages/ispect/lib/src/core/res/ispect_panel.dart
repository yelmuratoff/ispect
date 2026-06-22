import 'package:draggable_panel/draggable_panel.dart';
import 'package:flutter/widgets.dart';

/// The pieces ISpect assembles for the diagnostics panel, handed to an
/// [ISpectPanelBuilder] so consumers can return a fully customized
/// [DraggablePanel] without ISpect forwarding each `draggable_panel`
/// parameter individually.
@immutable
final class ISpectPanelData {
  const ISpectPanelData({
    required this.controller,
    required this.items,
    required this.buttons,
    required this.theme,
    required this.child,
  });

  /// The panel controller ISpect manages (or the one passed to `ISpectBuilder`).
  /// Pass it to `DraggablePanel.controller` so toggling and disposal stay wired.
  final DraggablePanelController controller;

  /// The assembled panel items: built-in tools (log viewer, performance,
  /// inspector, color picker), `ISpectOptions.panelItems`, and plugin entries.
  final List<DraggablePanelItem> items;

  /// The action buttons from `ISpectOptions.panelButtons`.
  final List<DraggablePanelButtonItem> buttons;

  /// ISpect's resolved default panel theme. Use it as-is or as a `copyWith` base.
  final DraggablePanelTheme theme;

  /// The app content the panel floats over. Pass it to `DraggablePanel.child`.
  final Widget? child;
}

/// Builds the diagnostics [DraggablePanel] from the pieces ISpect assembles.
///
/// Return a `DraggablePanel` configured however you like — every
/// `draggable_panel` parameter (content/shell builders, motion, behavior flags,
/// tooltips, sizing), including ones added in future `draggable_panel`
/// releases, is available here without ISpect having to forward each one.
typedef ISpectPanelBuilder = DraggablePanel Function(
  BuildContext context,
  ISpectPanelData data,
);
