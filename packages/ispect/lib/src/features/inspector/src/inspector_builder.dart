import 'package:flutter/material.dart';
import 'package:inspector/inspector.dart' as pkg_inspector;
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/controllers/draggable_button_controller.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/features/ispect/presentation/screens/logs_screen.dart';
import 'package:ispect/src/features/performance/src/builder.dart';

/// A widget that wraps your app with ISpect debugging tools.
///
/// **Warning: Never include in production builds - contains sensitive debug data.**
///
/// This widget adds debugging capabilities around your main app widget:
/// - Inspector panel for UI debugging
/// - Performance monitoring overlay
/// - Navigation tracking
///
/// ## Safe Usage
///
/// ```dart
/// const bool kEnableISpect = bool.fromEnvironment('ISPECT_ENABLED');
///
/// MaterialApp(
///   builder: (context, child) {
///     if (kEnableISpect) {
///       return ISpectBuilder(child: child);
///     }
///     return child;
///   },
///   home: MyApp(),
/// )
/// ```
///
/// Build commands:
/// ```bash
/// # Development
/// flutter run --dart-define=ISPECT_ENABLED=true
///
/// # Production (ISpect removed)
/// flutter build apk
/// ```
class ISpectBuilder extends StatefulWidget {
  /// Creates an ISpectBuilder that wraps [child] with debugging tools.
  ///
  /// Set [isISpectEnabled] to false to hide the panel at runtime (e.g. non-admin users).
  /// Compile-time gating is handled by [kISpectEnabled] via `--dart-define=ISPECT_ENABLED=true`.
  const ISpectBuilder({
    required this.child,
    required this.options,
    this.isISpectEnabled = kISpectEnabled,
    this.theme,
    this.controller,
    super.key,
  });

  /// Wraps [child] with ISpect debugging tools when enabled.
  ///
  /// This is the recommended way to use ISpect - no conditional logic needed
  /// in your code. When `kISpectEnabled` is `false`, simply returns [child].
  ///
  /// Use [isISpectEnabled] to control visibility at runtime (e.g., for admins only).
  /// The global `kISpectEnabled` controls tree-shaking at compile time.
  static Widget wrap({
    required Widget child,
    bool isISpectEnabled = kISpectEnabled,
    ISpectOptions? options,
    ISpectTheme? theme,
    DraggablePanelController? controller,
  }) {
    if (!kISpectEnabled || !isISpectEnabled) return child;

    return ISpectBuilder(
      options: options,
      theme: theme,
      controller: controller,
      isISpectEnabled: isISpectEnabled,
      child: child,
    );
  }

  /// Your main app widget.
  final Widget child;

  /// ISpect configuration options.
  final ISpectOptions? options;

  /// Custom theme for ISpect interface.
  final ISpectTheme? theme;

  /// Whether debugging tools are enabled. Set to false in production.
  final bool isISpectEnabled;

  /// Controller for the draggable debug panel.
  final DraggablePanelController? controller;

  @override
  State<ISpectBuilder> createState() => _ISpectBuilderState();
}

class _ISpectBuilderState extends State<ISpectBuilder> {
  late ISpectScopeModel model;
  late final LogPageController _logPageController;
  late final DraggablePanelController _panelController;

  @override
  void initState() {
    super.initState();
    model = ISpectScopeModel();
    _logPageController = LogPageController();
    _panelController = widget.controller ?? DraggablePanelController();

    model
      ..isISpectEnabled = widget.isISpectEnabled
      ..options = (widget.options ?? model.options).copyWith(
        onShare: widget.options?.onShare,
        onOpenFile: widget.options?.onOpenFile,
      )
      ..theme = widget.theme ?? model.theme;

    // Apply initial settings to logger if provided
    _applyInitialSettings();
  }

  /// Applies initial settings from options to the logger.
  void _applyInitialSettings() {
    final initialSettings = widget.options?.initialSettings;
    if (initialSettings != null) {
      // Convert disabled types to enabled types for filter
      final enabledTypes = initialSettings.disabledLogTypes.isEmpty
          ? <String>[] // Empty = no filter (all enabled)
          : ISpectLogType.builtIn
              .map((e) => e.key)
              .where((key) => !initialSettings.disabledLogTypes.contains(key))
              .toList();

      ISpect.logger.configure(
        options: ISpect.logger.options.copyWith(
          enabled: initialSettings.enabled,
          useConsoleLogs: initialSettings.useConsoleLogs,
          useHistory: initialSettings.useHistory,
        ),
        filter: enabledTypes.isNotEmpty
            ? ISpectFilter(logTypeKeys: enabledTypes)
            : null,
      );
    }
  }

  @override
  void dispose() {
    _logPageController.dispose();
    if (widget.controller == null) {
      _panelController.dispose();
    }
    model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Early return when ISpect is disabled - enables tree-shaking
    if (!kISpectEnabled) {
      return widget.child;
    }

    return ListenableBuilder(
      listenable: model,
      builder: (context, _) {
        // Build the widget tree with the necessary layers.
        var currentChild = widget.child;

        // Add inspector from the inspector package.
        currentChild = pkg_inspector.Inspector(
          isPanelVisible: model.isISpectEnabled,
          isEnabled: model.isISpectEnabled,
          panelBuilder: _buildPanel,
          child: currentChild,
        );

        // Add performance overlay to the widget tree.
        currentChild = ISpectPerformanceOverlayBuilder(
          isPerformanceTrackingEnabled: model.isPerformanceTrackingEnabled,
          child: currentChild,
        );

        return ISpectScopeController(
          model: model,
          child: currentChild,
        );
      },
    );
  }

  Widget _buildPanel(
    BuildContext context,
    pkg_inspector.InspectorController controller,
    Widget child,
  ) {
    final iSpect = ISpect.read(context);
    final options = iSpect.options;
    final theme = context.ispectTheme;

    return ListenableBuilder(
      listenable: Listenable.merge([
        controller.modeNotifier,
        _logPageController,
      ]),
      child: child,
      builder: (context, child) => DraggablePanel(
        theme: theme.panelTheme ?? _buildDefaultPanelTheme(context),
        controller: _panelController,
        items: [
          if (options.isLogPageEnabled)
            DraggablePanelItem(
              icon: _logPageController.inLoggerPage
                  ? Icons.undo_rounded
                  : Icons.reorder_rounded,
              enableBadge: _logPageController.inLoggerPage,
              onTap: (_) => _launchInfospect(context, options),
              description: _logPageController.inLoggerPage
                  ? context.ispectL10n.backToMainScreen
                  : context.ispectL10n.openLogViewer,
            ),
          if (options.isPerformanceEnabled)
            DraggablePanelItem(
              icon: Icons.monitor_heart_outlined,
              enableBadge: iSpect.isPerformanceTrackingEnabled,
              onTap: (_) => iSpect.togglePerformanceTracking(),
              description: context.ispectL10n.togglePerformanceTracking,
            ),
          if (options.isInspectorEnabled)
            DraggablePanelItem(
              icon: Icons.format_shapes_rounded,
              enableBadge: controller.modeNotifier.value ==
                  pkg_inspector.InspectorMode.inspector,
              onTap: (_) => controller.setMode(
                controller.modeNotifier.value ==
                        pkg_inspector.InspectorMode.inspector
                    ? pkg_inspector.InspectorMode.none
                    : pkg_inspector.InspectorMode.inspector,
              ),
              description: context.ispectL10n.inspectWidgets,
            ),
          if (options.isColorPickerEnabled)
            DraggablePanelItem(
              icon: Icons.colorize_rounded,
              enableBadge: controller.modeNotifier.value ==
                  pkg_inspector.InspectorMode.colorPicker,
              onTap: (ctx) => controller.setMode(
                controller.modeNotifier.value ==
                        pkg_inspector.InspectorMode.colorPicker
                    ? pkg_inspector.InspectorMode.none
                    : pkg_inspector.InspectorMode.colorPicker,
                context: ctx,
              ),
              description: context.ispectL10n.zoomPickColor,
            ),
          ...options.panelItems,
        ],
        buttons: options.panelButtons,
        child: child,
      ),
    );
  }

  DraggablePanelTheme _buildDefaultPanelTheme(BuildContext context) {
    final theme = context.ispectTheme;

    return DraggablePanelTheme(
      draggableButtonColor: theme.card?.resolve(context),
      panelBackgroundColor: theme.background?.resolve(context),
      panelItemColor: theme.card?.resolve(context),
      foregroundColor: theme.foreground?.resolve(context),
      panelBorder: switch (theme.divider?.resolve(context)) {
        final color? => Border.all(color: color),
        null => null,
      },
    );
  }

  Future<void> _launchInfospect(
    BuildContext context,
    ISpectOptions options,
  ) async {
    final iSpect = ISpect.read(context);
    final iSpectScreen = MaterialPageRoute<dynamic>(
      builder: (_) => LogsScreen(
        options: options,
        appBarTitle: iSpect.theme.pageTitle,
      ),
      settings: const RouteSettings(name: 'ISpect Screen'),
    );
    if (_logPageController.inLoggerPage) {
      options.pop(context);
    } else {
      _logPageController.setInLoggerPage(isLoggerPage: true);
      await options.push(context, iSpectScreen);
      if (context.mounted) {
        _logPageController.setInLoggerPage(isLoggerPage: false);
      }
    }
  }
}
