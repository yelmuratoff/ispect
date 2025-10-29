import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/utils/adjust_color.dart';
import 'package:ispect/src/features/inspector/inspector.dart';
import 'package:ispect/src/features/performance/src/builder.dart';

/// A widget that wraps your app with ISpect debugging tools.
///
/// **⚠️ WARNING: Never include in production builds - contains sensitive debug data.**
///
/// This widget adds debugging capabilities around your main app widget:
/// - Inspector panel for UI debugging
/// - Performance monitoring overlay
/// - Feedback system for bug reporting
/// - Navigation tracking
///
/// ## Safe Usage
///
/// ```dart
/// const bool kEnableISpect = bool.fromEnvironment('ENABLE_ISPECT');
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
/// flutter run --dart-define=ENABLE_ISPECT=true
///
/// # Production (ISpect removed)
/// flutter build apk
/// ```
class ISpectBuilder extends StatefulWidget {
  /// Creates an ISpectBuilder that wraps [child] with debugging tools.
  ///
  /// Set [isISpectEnabled] to false in production for security.
  const ISpectBuilder({
    required this.child,
    required this.options,
    this.isISpectEnabled = kDebugMode,
    this.theme,
    this.controller,
    super.key,
  });

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

  @override
  void initState() {
    super.initState();
    model = ISpectScopeModel();

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
          : ISpectLogType.values
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
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: model,
        builder: (context, _) {
          final theme = Theme.of(context);

          // Build the widget tree with the necessary layers.
          var currentChild = widget.child;

          // Add inspector to the widget tree.
          currentChild = Inspector(
            isPanelVisible: model.isISpectEnabled,
            backgroundColor: adjustColorBrightness(
              theme.colorScheme.primaryContainer,
              0.6,
            ),
            selectedColor: theme.colorScheme.primaryContainer,
            textColor: theme.colorScheme.onSurface,
            selectedTextColor: theme.colorScheme.onSurface,
            controller: widget.controller,
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
