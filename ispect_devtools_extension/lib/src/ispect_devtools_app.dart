import 'dart:async';

import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect_devtools_extension/src/vm_log_source.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vm_service/vm_service.dart';

/// The ISpect tab: the debugged app's log history in ISpect's own viewer.
class ISpectDevToolsApp extends StatefulWidget {
  const ISpectDevToolsApp({super.key});

  @override
  State<ISpectDevToolsApp> createState() => _ISpectDevToolsAppState();
}

class _ISpectDevToolsAppState extends State<ISpectDevToolsApp> {
  late final ISpectLogger _logger;
  late final ISpectVmLogSource _source;
  late final ISpectScopeModel _scope;

  @override
  void initState() {
    super.initState();
    _logger = ISpectLogger(options: ISpectLoggerOptions(useConsoleLogs: false));
    ISpect.initialize(_logger);
    _logger.clearHistory();
    _scope = ISpectScopeModel(isISpectEnabled: true, theme: _theme());
    extensionManager.darkThemeEnabled.addListener(_applyTheme);
    _source = ISpectVmLogSource(call: _callExtension, sink: _logger);
    unawaited(_startWhenConnected());
  }

  ISpectTheme _theme() => ISpectTheme(
    themeMode: extensionManager.darkThemeEnabled.value
        ? ISpectThemeMode.dark
        : ISpectThemeMode.light,
  );

  void _applyTheme() => _scope.theme = _theme();

  Future<void> _startWhenConnected() async {
    await serviceManager.onServiceAvailable;
    if (mounted) _source.start();
  }

  Future<Map<String, Object?>> _callExtension(
    String method,
    Map<String, String> args,
  ) async {
    try {
      final response = await serviceManager.callServiceExtensionOnMainIsolate(
        method,
        args: args,
      );
      return response.json ?? const {};
    } on RPCError catch (error) {
      if (error.code == RPCErrorKind.kMethodNotFound.code) {
        throw const ISpectExtensionMissing();
      }
      if (error.code == RPCErrorKind.kInvalidParams.code &&
          args.containsKey('afterId')) {
        throw const ISpectCursorExpired();
      }
      rethrow;
    }
  }

  @override
  void dispose() {
    extensionManager.darkThemeEnabled.removeListener(_applyTheme);
    _source.dispose();
    _scope.dispose();
    unawaited(ISpect.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ISpectScopeController(
    model: _scope,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: ISpectLocalization.localizationDelegates,
      supportedLocales: ISpectLocalization.supportedLocales,
      home: ValueListenableBuilder<ISpectVmLogStatus>(
        valueListenable: _source.status,
        builder: (context, status, _) => switch (status) {
          ISpectVmLogStatus.live => const ISpectLogsScreen(title: 'ISpect'),
          ISpectVmLogStatus.connecting => const _StatusMessage(
            showProgress: true,
            message: 'Waiting for ISpect in the running app…',
          ),
          ISpectVmLogStatus.notEnabled => const _StatusMessage(
            message:
                'This app has no ISpect diagnostics. Run it with '
                '--dart-define=ISPECT_ENABLED=true and initialize ISpect.',
          ),
          ISpectVmLogStatus.outdated => const _StatusMessage(
            message:
                'This app uses an older ISpect. Update ispect to '
                '8.0.0-dev.2 or newer to see its logs here.',
          ),
          ISpectVmLogStatus.unreachable => const _StatusMessage(
            showProgress: true,
            message: "Can't read ISpect logs from the running app. Retrying…",
          ),
        },
      ),
    ),
  );
}

class _StatusMessage extends StatelessWidget {
  const _StatusMessage({required this.message, this.showProgress = false});

  final String message;
  final bool showProgress;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: [
            if (showProgress) const CircularProgressIndicator(),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    ),
  );
}
