import 'package:ispect/ispect.dart';
import 'package:ispect/src/features/log_viewer/presentation/screens/logs_screen.dart';
import 'package:material_ui/material_ui.dart';

/// ISpect's log viewer for [ISpect.logger], shown outside the floating panel,
/// for example in a DevTools extension or a custom debug screen.
///
/// The viewer follows the logger live: entries added with
/// [ISpectLogger.logData] appear as they arrive. Place it below an
/// [ISpectScopeController] and a `MaterialApp` that registers
/// [ISpectLocalization.localizationDelegates].
final class ISpectLogsScreen extends StatelessWidget {
  const ISpectLogsScreen({
    this.options = const ISpectOptions(),
    this.title,
    super.key,
  });

  /// Callbacks and actions the viewer offers, such as sharing.
  final ISpectOptions options;

  /// The app bar title. Defaults to the ISpect theme's page title.
  final String? title;

  @override
  Widget build(BuildContext context) =>
      LogsScreen(options: options, appBarTitle: title);
}
