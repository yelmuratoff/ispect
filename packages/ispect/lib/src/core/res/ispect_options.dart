// ignore_for_file: use_if_null_to_convert_nulls_to_bools

import 'package:flutter/material.dart';
import 'package:ispect/src/common/models/action_item.dart';
import 'package:ispect/src/common/models/panel_button.dart';
import 'package:ispect/src/common/models/panel_item.dart';
import 'package:ispect/src/common/widgets/builder/data_builder.dart';

/// A configuration class for `ISpect`, defining various options including locale settings,
/// action items, and panel configurations.
///
/// This class allows customization of `ISpect` through parameters such as:
/// - Language settings (`locale`).
/// - Action items (`actionItems`).
/// - Custom panel items (`panelItems`).
/// - Additional panel buttons (`panelButtons`).
///
/// ### Example Usage:
/// ```dart
/// final options = ISpectOptions(
///   locale: Locale('en'),
///   actionItems: `ISpectActionItem(name: 'Log', onTap: () {})`,
///   panelItems: [
///     (icon: Icons.bug_report, enableBadge: true, onTap: (context) => showBugReport(context)),
///   ],
///   panelButtons: [
///     (icon: Icons.settings, label: 'Settings', onTap: (context) => openSettings(context)),
///   ],
/// );
/// ```
final class ISpectOptions {
  /// Creates an instance of `ISpectOptions` with customizable settings.
  ///
  /// - `locale`: The language setting for the application. Defaults to `'en'` (English).
  /// - `actionItems`: A list of actions that can be triggered within `ISpect`.
  /// - `panelItems`: A list of interactive items to be displayed in the panel.
  /// - `panelButtons`: A list of buttons for additional panel controls.
  const ISpectOptions({
    this.locale = const Locale('en'),
    this.actionItems = const [],
    this.panelItems = const [],
    this.panelButtons = const [],
    this.isLogPageEnabled = true,
    this.isPerformanceEnabled = true,
    this.isInspectorEnabled = true,
    this.isFeedbackEnabled = true,
    this.isColorPickerEnabled = true,
    this.isThemeSchemaEnabled = true,
    this.itemsBuilder,
  });

  /// The locale setting for `ISpect`, defining the language and region preferences.
  ///
  /// Defaults to `Locale('en')`.
  final Locale locale;

  /// [isLogPageEnabled] - Controls visibility of the log viewer page.
  final bool isLogPageEnabled;

  /// [isPerformanceEnabled] - Controls visibility of performance monitoring tools.
  final bool isPerformanceEnabled;

  /// [isInspectorEnabled] - Controls visibility of the widget inspector.
  final bool isInspectorEnabled;

  /// [isFeedbackEnabled] - Controls visibility of the feedback reporting tool.
  final bool isFeedbackEnabled;

  /// [isColorPickerEnabled] - Controls visibility of the color picker tool.
  final bool isColorPickerEnabled;

  /// [isThemeSchemaEnabled] - Controls visibility of the theme schema inspector.
  final bool isThemeSchemaEnabled;

  /// A list of action items that can be triggered in `ISpect`.
  ///
  /// This typically includes debugging, logging, or inspection actions.
  final List<ISpectActionItem> actionItems;

  /// A list of panel items, each containing an icon, badge visibility, and a tap handler.
  ///
  /// The structure of each panel item:
  /// ```dart
  /// ({
  ///   IconData icon,
  ///   bool enableBadge,
  ///   void Function(BuildContext context) onTap
  /// })
  /// ```
  ///
  /// - `icon`: The icon representing the panel item.
  /// - `enableBadge`: A flag to determine if a notification badge should be shown.
  /// - `onTap`: A callback function triggered when the item is tapped.
  final List<ISpectPanelItem> panelItems;

  /// A list of panel buttons, each containing an icon, label, and a tap handler.
  ///
  /// The structure of each button:
  /// ```dart
  /// ({
  ///   IconData icon,
  ///   String label,
  ///   void Function(BuildContext context) onTap
  /// })
  /// ```
  ///
  /// - `icon`: The button's icon.
  /// - `label`: The text label displayed for the button.
  /// - `onTap`: A callback function triggered when the button is tapped.
  final List<ISpectPanelButtonItem> panelButtons;

  /// A builder for customizing the data displayed in the `ISpect` screen.
  final ISpectifyDataBuilder? itemsBuilder;

  /// Creates a new `ISpectOptions` instance with updated values while retaining
  /// existing ones where not specified.
  ///
  /// - `locale`: The updated locale (if provided).
  /// - `actionItems`: A new list of action items (if provided).
  /// - `panelItems`: A new list of panel items (if provided).
  /// - `panelButtons`: A new list of panel buttons (if provided).
  ///
  /// ### Example Usage:
  /// ```dart
  /// final updatedOptions = options.copyWith(locale: Locale('es'));
  /// ```
  ISpectOptions copyWith({
    Locale? locale,
    List<ISpectActionItem>? actionItems,
    List<ISpectPanelItem>? panelItems,
    List<ISpectPanelButtonItem>? panelButtons,
  }) =>
      ISpectOptions(
        locale: locale ?? this.locale,
        actionItems: actionItems ?? this.actionItems,
        panelItems: panelItems ?? this.panelItems,
        panelButtons: panelButtons ?? this.panelButtons,
      );
}
