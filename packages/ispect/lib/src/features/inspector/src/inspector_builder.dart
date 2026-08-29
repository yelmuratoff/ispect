import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/utils/logger_settings.dart';
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
    'tree-shaking in release builds. The constructor will be made private '
    'in 8.0.0.',
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
  late final GlobalKey<NavigatorState> _navigatorKey;

  /// Drives pointer passthrough: `false` keeps the navigator transparent and
  /// non-interactive so the app below stays usable while no ISpect route is open.
  late final ValueNotifier<bool> _hasOverlayRoute;
  bool _isInitialized = false;
  int _overlayDepth = 0;

  @override
  void initState() {
    super.initState();
    if (!kISpectEnabled) return;

    model = ISpectScopeModel();
    _logPageController = ISpectLogPageController();
    _panelController =
        widget.controller ??
        DraggablePanelController(
          initialPlacement: const PanelPlacement.stashed(PanelEdge.end),
        );
    _navigatorKey = GlobalKey<NavigatorState>();
    _hasOverlayRoute = ValueNotifier<bool>(false);
    _isInitialized = true;

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
  }

  void _applyInitialSettings() {
    final initialSettings = widget.options?.initialSettings;
    if (initialSettings == null) return;
    applySettingsToLogger(ISpect.logger, initialSettings);
  }

  @override
  void dispose() {
    if (!_isInitialized) {
      super.dispose();
      return;
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

        return ISpectScopeController(model: model, child: currentChild);
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
          actionTheme:
              theme.panelActionTheme ?? _buildDefaultActionTheme(context),
          buttons: options.panelButtons,
          child: child,
          actions: [
            if (settings.isLogPageEnabled)
              PanelAction(
                icon: _logPageController.inLoggerPage
                    ? Icons.undo_rounded
                    : Icons.reorder_rounded,
                badge: _logPageController.inLoggerPage
                    ? const PanelBadge.dot()
                    : null,
                onPressed: () => _launchInfospect(context, options),
                label: _logPageController.inLoggerPage
                    ? context.ispectL10n.back
                    : context.ispectL10n.logs,
                tooltip: _logPageController.inLoggerPage
                    ? context.ispectL10n.backToMainScreen
                    : context.ispectL10n.openLogViewer,
              ),
            if (settings.isPerformanceEnabled)
              PanelAction(
                icon: Icons.monitor_heart_outlined,
                badge: iSpect.isPerformanceTrackingEnabled
                    ? const PanelBadge.dot()
                    : null,
                onPressed: iSpect.togglePerformanceTracking,
                label: context.ispectL10n.performance,
                tooltip: context.ispectL10n.togglePerformanceTracking,
              ),
            if (settings.isInspectorEnabled)
              PanelAction(
                icon: Icons.format_shapes_rounded,
                badge:
                    controller.modeNotifier.value ==
                        pkg_inspector.InspectorMode.inspector
                    ? const PanelBadge.dot()
                    : null,
                onPressed: () => controller.setMode(
                  controller.modeNotifier.value ==
                          pkg_inspector.InspectorMode.inspector
                      ? pkg_inspector.InspectorMode.none
                      : pkg_inspector.InspectorMode.inspector,
                ),
                label: context.ispectL10n.inspector,
                tooltip: context.ispectL10n.inspectWidgets,
              ),
            if (settings.isColorPickerEnabled)
              PanelAction(
                icon: Icons.colorize_rounded,
                badge:
                    controller.modeNotifier.value ==
                        pkg_inspector.InspectorMode.colorPicker
                    ? const PanelBadge.dot()
                    : null,
                onPressed: () => controller.setMode(
                  controller.modeNotifier.value ==
                          pkg_inspector.InspectorMode.colorPicker
                      ? pkg_inspector.InspectorMode.none
                      : pkg_inspector.InspectorMode.colorPicker,
                  context: context,
                ),
                label: context.ispectL10n.colorPicker,
                tooltip: context.ispectL10n.zoomPickColor,
              ),
            if (ISpect.senders.isNotEmpty)
              PanelAction(
                icon: Icons.api_rounded,
                onPressed: () => _launchComposer(context, options),
                label: context.ispectL10n.composer,
                tooltip: context.ispectL10n.composerTitle,
              ),
            ...options.panelItems,
            // Plugin-generated panel items
            for (final plugin in options.plugins)
              PanelAction(
                icon: plugin.icon,
                badge: plugin.enableBadge ? const PanelBadge.dot() : null,
                label: plugin.title,
                tooltip: plugin.description ?? plugin.title,
                onPressed: () => _launchPluginScreen(context, plugin, options),
              ),
          ],
        );

        final panelBuilder = options.panelBuilder;
        if (panelBuilder != null) return panelBuilder(context, data);

        return DraggableActionPanel(
          theme: data.theme,
          actionTheme: data.actionTheme,
          controller: data.controller,
          actions: data.actions,
          buttons: data.buttons,
          title: iSpect.theme.pageTitle,
          onClose: data.controller.stash,
          behavior: const PanelBehavior(collapsible: false),
          child: data.child,
        );
      },
    );
  }

  DraggablePanelThemeData _buildDefaultPanelTheme(BuildContext context) {
    final theme = context.ispectTheme;

    // draggable_panel resolves a null token from the ambient ColorScheme.
    if (theme.useHostColors) {
      return _panelShell(theme.divider?.resolve(context)).copyWith(
        surfaceColor: theme.background?.resolve(context),
        handleColor: theme.foreground?.resolve(context),
      );
    }

    return _panelShell(
      _ownedColor(context, theme.divider, ISpectDefaultPalette.divider),
    ).copyWith(
      surfaceColor: _ownedColor(
        context,
        theme.background,
        ISpectDefaultPalette.background,
      ),
      handleColor: _ownedColor(
        context,
        theme.foreground,
        ISpectDefaultPalette.foreground,
      ),
    );
  }

  DraggableActionPanelThemeData _buildDefaultActionTheme(BuildContext context) {
    final theme = context.ispectTheme;
    final materialTheme = Theme.of(context);
    final useHost = theme.useHostColors;

    final background = useHost
        ? theme.card?.resolve(context)
        : _ownedColor(context, theme.card, ISpectDefaultPalette.card);
    final foreground = useHost
        ? theme.foreground?.resolve(context)
        : _ownedColor(
            context,
            theme.foreground,
            ISpectDefaultPalette.foreground,
          );

    return _actionShapes.copyWith(
      actionBackgroundColor: background,
      actionForegroundColor: foreground,
      collapsedIconColor: foreground,
      headerStyle: materialTheme.textTheme.titleSmall?.copyWith(
        color: foreground,
      ),
      closeButtonStyle:
          DraggableActionPanelThemeData.defaults(
            materialTheme.colorScheme,
          ).closeButtonStyle?.copyWith(
            foregroundColor: foreground == null
                ? null
                : WidgetStatePropertyAll(foreground),
            shape: WidgetStatePropertyAll(_gridShape),
          ),
    );
  }

  /// The panel shell ISpect owns regardless of palette: squircle corners on
  /// every face, and a parked panel that recedes.
  ///
  DraggablePanelThemeData _panelShell(Color? border) {
    final shape = _panelShape(border, ISpectConstants.panelBorderRadius);
    return DraggablePanelThemeData(
      collapsedShape: shape,
      stashedShape: shape,
      shape: shape,
      stashedOpacity: ISpectConstants.stashedPanelOpacity,
    );
  }

  /// The grid's own corners, a step down from the panel's.
  OutlinedBorder get _gridShape => ISpectSquircle.border();

  DraggableActionPanelThemeData get _actionShapes =>
      DraggableActionPanelThemeData(
        actionShape: _gridShape,
        buttonStyle: ButtonStyle(shape: WidgetStatePropertyAll(_gridShape)),
      );

  Color _ownedColor(
    BuildContext context,
    ISpectDynamicColor? override,
    ISpectDynamicColor fallback,
  ) =>
      override?.resolve(context) ??
      fallback.pick(isDark: context.ispectIsDark)!;

  ShapeBorder _panelShape(Color? border, double radius) =>
      ISpectSquircle.border(
        radius: radius,
        side: border == null ? BorderSide.none : BorderSide(color: border),
      );

  void _enterOverlay() {
    _overlayDepth++;
    _hasOverlayRoute.value = true;
    _panelController.collapse();
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
      builder: (_) =>
          LogsScreen(options: options, appBarTitle: iSpect.theme.pageTitle),
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
        builder: (context, hasRoute, navigator) =>
            IgnorePointer(ignoring: !hasRoute, child: navigator),
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
