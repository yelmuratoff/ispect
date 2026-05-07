import 'package:flutter/widgets.dart';

/// Base class for ISpect inspector plugins.
///
/// Plugins extend the inspector panel with custom screens accessible
/// via the draggable panel.
///
/// Example:
/// ```dart
/// // 1. Define plugin
/// class DeviceInfoPlugin extends InspectorPlugin {
///   @override
///   String get id => 'device-info';
///
///   @override
///   String get title => 'Device Info';
///
///   @override
///   IconData get icon => Icons.phone_android;
///
///   @override
///   Widget buildScreen(BuildContext context) => const DeviceInfoScreen();
/// }
///
/// // 2. Register
/// ISpectBuilder.wrap(
///   options: ISpectOptions(
///     plugins: [DeviceInfoPlugin()],
///   ),
///   child: MyApp(),
/// )
/// ```
abstract class InspectorPlugin {
  const InspectorPlugin();

  /// Unique identifier for this plugin.
  /// Used for deduplication and settings persistence.
  String get id;

  /// Human-readable title shown in panel tooltip and screen app bar.
  String get title;

  /// Icon shown in the draggable panel.
  IconData get icon;

  /// Optional description shown on long-press of the panel item.
  String? get description => null;

  /// Whether to show a badge indicator on the panel item.
  /// Override to provide dynamic badge state.
  bool get enableBadge => false;

  /// Build the full-screen widget for this plugin.
  /// Called when the user taps the plugin's panel item.
  Widget buildScreen(BuildContext context);

  /// Called once when ISpectBuilder initializes.
  /// Use for one-time setup (register listeners, load data).
  void onInit() {}

  /// Called when ISpectBuilder disposes.
  /// Use for cleanup (cancel subscriptions, release resources).
  void onDispose() {}
}
