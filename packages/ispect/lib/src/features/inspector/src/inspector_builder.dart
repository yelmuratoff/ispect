import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/utils/squircle.dart';
import 'package:ispect/src/common/widgets/error_boundary.dart';
import 'package:ispect/src/core/res/constants/ispect_constants.dart';
import 'package:ispect/src/core/res/ispect_default_palette.dart';
import 'package:ispect/src/features/http_composer/presentation/screens/http_composer_screen.dart';
import 'package:ispect/src/features/log_viewer/controllers/log_page_controller.dart';
import 'package:ispect/src/features/log_viewer/presentation/screens/logs_screen.dart';
import 'package:ispect/src/features/performance/src/builder.dart';
import 'package:ispect_layout/ispect_layout.dart' as pkg_inspector;

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
/// Prefer the [ISpectBuilder.wrap] factory — it short-circuits before
/// constructing the widget when `kISpectEnabled` is `false`, which lets the
/// Dart compiler tree-shake the ISpect widget tree out of release builds.
/// The public constructor is kept for backwards compatibility but defers
/// the disabled-build short-circuit to `build()`, which keeps the state
/// class reachable from a code-size standpoint.
///
/// ```dart
/// MaterialApp(
///   builder: (_, child) => ISpectBuilder.wrap(child: child!),
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
  @Deprecated(
    'Use ISpectBuilder.wrap. The wrap factory short-circuits before '
    'constructing the widget when kISpectEnabled is false, preserving '
    'tree-shaking in release builds. The constructor is scheduled to be '
    'made private in a stable 5.x release.',
  )
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

    // ignore: deprecated_member_use_from_same_package
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
  late final ISpectLogPageController _logPageController;
  late final DraggablePanelController _panelController;

  /// Navigator that hosts ISpect's own screens, decoupled from the host router.
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  /// Drives pointer passthrough: `false` keeps the navigator transparent and
  /// non-interactive so the app below stays usable while no ISpect route is open.
  final ValueNotifier<bool> _hasOverlayRoute = ValueNotifier<bool>(false);
  int _overlayDepth = 0;

  ErrorWidgetBuilder? _originalErrorWidgetBuilder;

  @override
  void initState() {
    super.initState();
    model = ISpectScopeModel();
    _logPageController = ISpectLogPageController();
    _panelController = widget.controller ?? DraggablePanelController();

    model
      ..isISpectEnabled = widget.isISpectEnabled
      ..options = (widget.options ?? model.options).copyWith(
        observer: widget.options?.observer ?? ISpectNavigatorObserver.current,
        onShare: widget.options?.onShare,
        onOpenFile: widget.options?.onOpenFile,
      )
      ..theme = widget.theme ?? model.theme;

    final initialSettings = widget.options?.initialSettings;
    if (initialSettings != null) {
      model.settings = initialSettings;
    }

    _applyInitialSettings();

    for (final plugin in widget.options?.plugins ?? <InspectorPlugin>[]) {
      plugin.onInit();
    }

    // Override ErrorWidget.builder to show a styled fallback for ISpect routes
    _originalErrorWidgetBuilder = ErrorWidget.builder;
    ErrorWidget.builder = _buildErrorWidget;
  }

  void _applyInitialSettings() {
    final initialSettings = widget.options?.initialSettings;
    if (initialSettings != null) {
      final enabledTypes = initialSettings.disabledLogTypes.isEmpty
          ? <String>[]
          : ISpectLogType.builtIn
              .map((e) => e.key)
              .where((key) => !initialSettings.disabledLogTypes.contains(key))
              .toList();

      ISpect.logger.configure(
        options: ISpect.logger.options.copyWith(
          enabled: initialSettings.enabled,
          useConsoleLogs: initialSettings.useConsoleLogs,
          useHistory: initialSettings.useHistory,
          forwardErrorToConsole: initialSettings.forwardErrorToConsole,
          maxHistoryItems: initialSettings.maxHistoryItems,
          logTruncateLength: initialSettings.logTruncateLength,
        ),
        filter: enabledTypes.isNotEmpty
            ? ISpectFilter(logTypeKeys: enabledTypes)
            : null,
      );
    }
  }

  @override
  void dispose() {
    // Restore original ErrorWidget.builder
    if (_originalErrorWidgetBuilder != null) {
      ErrorWidget.builder = _originalErrorWidgetBuilder!;
    }

    // Dispose plugins
    for (final plugin in widget.options?.plugins ?? <InspectorPlugin>[]) {
      plugin.onDispose();
    }

    _logPageController.dispose();
    if (widget.controller == null) {
      _panelController.dispose();
    }
    _hasOverlayRoute.dispose();
    model.dispose();
    super.dispose();
  }

  Widget _buildErrorWidget(FlutterErrorDetails details) =>
      _ISpectRenderErrorFallback(details: details);

  @override
  Widget build(BuildContext context) {
    // Early return when ISpect is disabled - enables tree-shaking
    if (!kISpectEnabled) {
      return widget.child;
    }

    return ListenableBuilder(
      listenable: model,
      builder: (context, _) {
        var currentChild = widget.child;

        // Host ISpect's own screens so its navigation never touches the host router.
        currentChild = _ISpectNavigationHost(
          navigatorKey: _navigatorKey,
          hasOverlayRoute: _hasOverlayRoute,
          child: currentChild,
        );

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
          enableJankLogging: model.options.enableJankLogging,
          severeJankFactor: model.options.severeJankFactor,
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
    final settings = iSpect.settings;

    return ListenableBuilder(
      listenable: Listenable.merge([
        controller.modeNotifier,
        _logPageController,
      ]),
      child: child,
      builder: (context, child) {
        final data = ISpectPanelData(
          controller: _panelController,
          theme: theme.panelTheme ?? _buildDefaultPanelTheme(context),
          buttons: options.panelButtons,
          child: child,
          items: [
            if (settings.isLogPageEnabled)
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
            if (settings.isPerformanceEnabled)
              DraggablePanelItem(
                icon: Icons.monitor_heart_outlined,
                enableBadge: iSpect.isPerformanceTrackingEnabled,
                onTap: (_) => iSpect.togglePerformanceTracking(),
                description: context.ispectL10n.togglePerformanceTracking,
              ),
            if (settings.isInspectorEnabled)
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
            if (settings.isColorPickerEnabled)
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
            if (ISpect.senders.isNotEmpty)
              DraggablePanelItem(
                icon: Icons.api_rounded,
                enableBadge: false,
                onTap: (ctx) => _launchComposer(ctx, options),
                description: context.ispectL10n.composerTitle,
              ),
            ...options.panelItems,
            // Plugin-generated panel items
            for (final plugin in options.plugins)
              DraggablePanelItem(
                icon: plugin.icon,
                enableBadge: plugin.enableBadge,
                description: plugin.description ?? plugin.title,
                onTap: (context) =>
                    _launchPluginScreen(context, plugin, options),
              ),
          ],
        );

        final panelBuilder = options.panelBuilder;
        if (panelBuilder != null) return panelBuilder(context, data);

        return DraggablePanel(
          theme: data.theme,
          controller: data.controller,
          items: data.items,
          buttons: data.buttons,
          child: data.child,
        );
      },
    );
  }

  DraggablePanelTheme _buildDefaultPanelTheme(BuildContext context) {
    final theme = context.ispectTheme;

    // Host-colors mode keeps the pre-6.0 behaviour: leave unset colours null so
    // DraggablePanel falls back to its own defaults.
    if (theme.useHostColors) {
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

    final dark = context.ispectIsDark;
    Color owned(ISpectDynamicColor? override, ISpectDynamicColor fallback) =>
        override?.resolve(context) ?? fallback.pick(isDark: dark)!;

    return DraggablePanelTheme(
      draggableButtonColor: owned(theme.card, ISpectDefaultPalette.card),
      panelBackgroundColor:
          owned(theme.background, ISpectDefaultPalette.background),
      panelItemColor: owned(theme.card, ISpectDefaultPalette.card),
      foregroundColor: owned(theme.foreground, ISpectDefaultPalette.foreground),
      panelBorder: Border.all(
        color: owned(theme.divider, ISpectDefaultPalette.divider),
      ),
    );
  }

  void _enterOverlay() {
    _overlayDepth++;
    _hasOverlayRoute.value = true;
  }

  void _exitOverlay() {
    if (_overlayDepth > 0) _overlayDepth--;

    if (mounted) _hasOverlayRoute.value = _overlayDepth > 0;
  }

  Future<void> _launchComposer(
    BuildContext context,
    ISpectOptions options,
  ) async {
    final navigator = _navigatorKey.currentState;
    if (navigator == null) return;

    final route = MaterialPageRoute<void>(
      builder: (_) => ISpectScopeController(
        model: model,
        child: HttpComposerScreen(
          senders: ISpect.senders,
          onPickComposerFile: options.onPickComposerFile,
        ),
      ),
      settings: const RouteSettings(name: 'ISpect HTTP Composer'),
    );

    _enterOverlay();
    try {
      await navigator.push(route);
    } finally {
      _exitOverlay();
    }
  }

  Future<void> _launchPluginScreen(
    BuildContext context,
    InspectorPlugin plugin,
    ISpectOptions options,
  ) async {
    final navigator = _navigatorKey.currentState;
    if (navigator == null) return;

    final route = MaterialPageRoute<void>(
      builder: (_) => ISpectScopeController(
        model: model,
        // Use Builder so that buildScreen receives a context
        // that has ISpectScopeController as an ancestor,
        // giving plugins access to context.iSpect, context.ispectTheme, etc.
        child: Builder(
          builder: (scopeContext) => SafePluginScreen(
            pluginBuilder: (ctx) => plugin.buildScreen(ctx),
            pluginId: plugin.id,
          ),
        ),
      ),
      settings: RouteSettings(name: 'ISpect Plugin: ${plugin.id}'),
    );

    _enterOverlay();
    try {
      await navigator.push(route);
    } finally {
      _exitOverlay();
    }
  }

  Future<void> _launchInfospect(
    BuildContext context,
    ISpectOptions options,
  ) async {
    final navigator = _navigatorKey.currentState;
    if (navigator == null) return;

    if (_logPageController.inLoggerPage) {
      await navigator.maybePop();
      return;
    }

    final iSpect = ISpect.read(context);
    final iSpectScreen = MaterialPageRoute<dynamic>(
      builder: (_) => LogsScreen(
        options: options,
        appBarTitle: iSpect.theme.pageTitle,
      ),
      settings: const RouteSettings(name: 'ISpect Screen'),
    );

    _logPageController.setInLoggerPage(isLoggerPage: true);
    _enterOverlay();
    try {
      await navigator.push(iSpectScreen);
    } finally {
      _exitOverlay();
      if (mounted) {
        _logPageController.setInLoggerPage(isLoggerPage: false);
      }
    }
  }
}

/// Hosts ISpect's screens in a dedicated [Navigator] layered over the app.
///
/// ISpect renders its own screens (log viewer, plugins, JSON drill-downs) on
/// this navigator instead of the host app's, so its imperative push/pop never
/// depends on the host router's navigation contract. Declarative routers such
/// as `yx_navigation` override [NavigatorState.pop] in a way that rejects
/// imperatively pushed routes; isolating ISpect on its own navigator keeps it
/// working regardless of the host router and leaves the host untouched.
///
/// While no ISpect route is open the navigator holds only a transparent
/// placeholder and ignores pointers, so the app below stays fully interactive.
class _ISpectNavigationHost extends StatelessWidget {
  const _ISpectNavigationHost({
    required this.navigatorKey,
    required this.hasOverlayRoute,
    required this.child,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final ValueListenable<bool> hasOverlayRoute;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // A fresh hero scope avoids sharing the host navigator's HeroController,
    // which Flutter forbids across two navigators.
    Widget overlay = HeroControllerScope.none(
      child: ValueListenableBuilder<bool>(
        valueListenable: hasOverlayRoute,
        builder: (context, hasRoute, navigator) => IgnorePointer(
          ignoring: !hasRoute,
          child: navigator,
        ),
        child: Navigator(
          key: navigatorKey,
          onGenerateInitialRoutes: (_, __) => [
            PageRouteBuilder<void>(
              opaque: false,
              pageBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );

    // Route the system back button to the ISpect navigator, but only when a
    // Router owns it: BackButtonListener resolves Router.of and throws under a
    // plain (non-router) MaterialApp.
    if (Router.maybeOf(context) != null) {
      overlay = BackButtonListener(
        onBackButtonPressed: () async {
          final navigator = navigatorKey.currentState;
          if (navigator != null && navigator.canPop()) {
            await navigator.maybePop();
            return true;
          }
          return false;
        },
        child: overlay,
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        Positioned.fill(child: overlay),
      ],
    );
  }
}

/// Minimal fallback widget for layout/paint errors caught by
/// [ErrorWidget.builder] on ISpect routes.
///
/// Uses only base Material widgets and [Theme.of] colors to avoid
/// recursive failures if ISpect theming is broken.
class _ISpectRenderErrorFallback extends StatelessWidget {
  const _ISpectRenderErrorFallback({required this.details});

  final FlutterErrorDetails details;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final errorMessage = details.exceptionAsString().split('\n').first;

    return Material(
      color: colorScheme.surface,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Render error',
                  style: textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  errorMessage,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (kDebugMode && details.stack != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: ISpectSquircle.decoration(
                      color: colorScheme.surfaceContainerHighest,
                      radius: ISpectConstants.standardBorderRadius,
                    ),
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        details.stack.toString(),
                        style: textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
