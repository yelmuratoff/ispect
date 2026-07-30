import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ispect/src/common/utils/safe_diagnostic_snapshot.dart';
import 'package:ispect/src/common/utils/squircle.dart';
import 'package:ispect/src/core/res/constants/ispect_constants.dart';
import 'package:ispect/src/ispect.dart';
import 'package:ispectify/ispectify.dart';

/// A widget that catches errors thrown during [pluginBuilder] execution
/// and displays a styled fallback instead of the default red error screen.
///
/// Used to wrap plugin screens in the inspector panel so that a broken
/// plugin does not destroy the debugging experience.
class SafePluginScreen extends StatefulWidget {
  const SafePluginScreen({
    required this.pluginBuilder,
    required this.pluginId,
    super.key,
  });

  /// Builds the plugin screen widget. Called with the current [BuildContext].
  final Widget Function(BuildContext context) pluginBuilder;

  /// Identifier of the plugin, shown in the fallback UI.
  final String pluginId;

  @override
  State<SafePluginScreen> createState() => _SafePluginScreenState();
}

class _SafePluginScreenState extends State<SafePluginScreen> {
  String? _errorText;
  String? _stackTraceText;
  UniqueKey _childKey = UniqueKey();

  @override
  Widget build(BuildContext context) {
    if (_errorText != null) {
      return _ISpectErrorFallback(
        pluginId: widget.pluginId,
        errorText: _errorText!,
        stackTraceText: _stackTraceText,
        onRetry: _retry,
      );
    }

    try {
      return KeyedSubtree(
        key: _childKey,
        child: widget.pluginBuilder(context),
      );
    } catch (error, stackTrace) {
      final resourceLimits =
          ISpect.loggerIfInitialized?.options.resourceLimits ??
              DiagnosticResourceLimits.balanced;
      final errorText = ISpectSafeDiagnosticSnapshot.summary(
        error,
        resourceLimits: resourceLimits,
      );
      final stackTraceText = ISpectSafeDiagnosticSnapshot.text(
        stackTrace,
        resourceLimits: resourceLimits,
      );
      // Schedule state update — we are inside build().
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _errorText = errorText;
            _stackTraceText = stackTraceText;
          });
        }
      });

      // Return fallback immediately for this frame.
      return _ISpectErrorFallback(
        pluginId: widget.pluginId,
        errorText: errorText,
        stackTraceText: stackTraceText,
        onRetry: _retry,
      );
    }
  }

  void _retry() {
    setState(() {
      _errorText = null;
      _stackTraceText = null;
      _childKey = UniqueKey();
    });
  }
}

/// Minimal fallback widget shown when a plugin screen fails to render.
///
/// Uses only basic Material widgets and [Theme.of] colors — never depends
/// on [ISpectTheme] to avoid recursive failures if ISpect itself is broken.
class _ISpectErrorFallback extends StatelessWidget {
  const _ISpectErrorFallback({
    required this.pluginId,
    required this.errorText,
    required this.onRetry,
    this.stackTraceText,
  });

  final String pluginId;
  final String errorText;
  final String? stackTraceText;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final resourceLimits = ISpect.loggerIfInitialized?.options.resourceLimits ??
        DiagnosticResourceLimits.balanced;
    final safePluginId = ISpectSafeDiagnosticSnapshot.summary(
      pluginId,
      resourceLimits: resourceLimits,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Plugin Error: $safePluginId'),
        leading: const BackButton(),
      ),
      body: SafeArea(
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
                  'Failed to render plugin screen',
                  style: textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  errorText,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (kDebugMode &&
                    stackTraceText != null &&
                    stackTraceText!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ExpansionTile(
                    title: const Text('Stack Trace'),
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: ISpectSquircle.decoration(
                          color: colorScheme.surfaceContainerHighest,
                          radius: ISpectConstants.standardBorderRadius,
                        ),
                        child: SelectableText(
                          stackTraceText!,
                          style: textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Back'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
