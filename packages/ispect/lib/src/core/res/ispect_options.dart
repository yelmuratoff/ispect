// ignore_for_file: use_if_null_to_convert_nulls_to_bools

import 'package:flutter/material.dart';
import 'package:ispect/src/common/models/action_item.dart';
import 'package:ispect/src/common/models/panel_button.dart';
import 'package:ispect/src/common/models/panel_item.dart';
import 'package:ispect/src/common/widgets/builder/data_builder.dart';

/// A configuration class for `ISpect`, defining various options including locale settings,
/// feature toggles, action items, and panel configurations.
///
/// This class allows customization of `ISpect` through parameters such as:
/// - Language settings (`locale`).
/// - Feature toggles (`isLogPageEnabled`, `isPerformanceEnabled`, etc.).
/// - Action items (`actionItems`).
/// - Custom panel items (`panelItems`).
/// - Additional panel buttons (`panelButtons`).
/// - Custom data builder (`itemsBuilder`).
///
/// ### Example Usage:
/// ```dart
/// final options = ISpectOptions(
///   locale: const Locale('en'),
///   isLogPageEnabled: true,
///   isPerformanceEnabled: false,
///   actionItems: [
///     ISpectActionItem(
///       title: 'Clear Logs',
///       icon: Icons.clear_all,
///       onTap: (context) => clearLogs(),
///     ),
///   ],
///   panelItems: [
///     ISpectPanelItem(
///       icon: Icons.bug_report,
///       enableBadge: true,
///       onTap: (context) => showBugReport(context),
///     ),
///   ],
///   panelButtons: [
///     ISpectPanelButtonItem(
///       icon: Icons.settings,
///       label: 'Settings',
///       onTap: (context) => openSettings(context),
///     ),
///   ],
/// );
/// ```
final class ISpectOptions {
  /// Creates an instance of `ISpectOptions` with customizable settings.
  ///
  /// - `locale`: The language setting for the application. Defaults to `Locale('en')`.
  /// - `actionItems`: A list of custom actions that can be triggered within `ISpect`.
  /// - `panelItems`: A list of interactive items to be displayed in the panel.
  /// - `panelButtons`: A list of buttons for additional panel controls.
  /// - `isLogPageEnabled`: Controls visibility of the log viewer page. Defaults to `true`.
  /// - `isPerformanceEnabled`: Controls visibility of performance monitoring tools. Defaults to `true`.
  /// - `isInspectorEnabled`: Controls visibility of the widget inspector. Defaults to `true`.
  /// - `isFeedbackEnabled`: Controls visibility of the feedback reporting tool. Defaults to `true`.
  /// - `isColorPickerEnabled`: Controls visibility of the color picker tool. Defaults to `true`.
  /// - `isThemeSchemaEnabled`: Controls visibility of the theme schema inspector. Defaults to `true`.
  /// - `itemsBuilder`: Optional custom builder for the data displayed in the `ISpect` screen.
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

  /// Controls visibility of the log viewer page.
  ///
  /// When `true`, the log page will be available in the ISpect interface.
  /// Defaults to `true`.
  final bool isLogPageEnabled;

  /// Controls visibility of performance monitoring tools.
  ///
  /// When `true`, performance monitoring features will be available.
  /// Defaults to `true`.
  final bool isPerformanceEnabled;

  /// Controls visibility of the widget inspector.
  ///
  /// When `true`, the widget inspector will be available for debugging UI.
  /// Defaults to `true`.
  final bool isInspectorEnabled;

  /// Controls visibility of the feedback reporting tool.
  ///
  /// When `true`, users can access feedback and reporting features.
  /// Defaults to `true`.
  final bool isFeedbackEnabled;

  /// Controls visibility of the color picker tool.
  ///
  /// When `true`, the color picker utility will be available.
  /// Defaults to `true`.
  final bool isColorPickerEnabled;

  /// Controls visibility of the theme schema inspector.
  ///
  /// When `true`, theme and color scheme inspection tools will be available.
  /// Defaults to `true`.
  final bool isThemeSchemaEnabled;

  /// A list of custom action items that can be triggered in `ISpect`.
  ///
  /// Each action item contains:
  /// - `title`: The display name of the action
  /// - `icon`: The icon representing the action
  /// - `onTap`: A callback function triggered when the action is executed
  ///
  /// This typically includes debugging, logging, or inspection actions.
  final List<ISpectActionItem> actionItems;

  /// A list of panel items displayed in the `ISpect` interface.
  ///
  /// Each panel item is an `ISpectPanelItem` with the following properties:
  /// - `icon`: The icon representing the panel item
  /// - `enableBadge`: A flag to determine if a notification badge should be shown
  /// - `onTap`: A callback function triggered when the item is tapped
  final List<ISpectPanelItem> panelItems;

  /// A list of panel buttons for additional controls in the `ISpect` interface.
  ///
  /// Each panel button is an `ISpectPanelButtonItem` with the following properties:
  /// - `icon`: The button's icon
  /// - `label`: The text label displayed for the button
  /// - `onTap`: A callback function triggered when the button is tapped
  final List<ISpectPanelButtonItem> panelButtons;

  /// A builder for customizing the data displayed in the `ISpect` screen.
  ///
  /// When provided, this builder allows for custom rendering of data
  /// within the ISpect interface, enabling advanced customization scenarios.
  final ISpectifyDataBuilder? itemsBuilder;

  /// Creates a new `ISpectOptions` instance with updated values while retaining
  /// existing ones where not specified.
  ///
  /// All parameters are optional and when provided will override the corresponding
  /// values in the current instance.
  ///
  /// ### Example Usage:
  /// ```dart
  /// final updatedOptions = options.copyWith(
  ///   locale: const Locale('es'),
  ///   isLogPageEnabled: false,
  /// );
  /// ```
  ISpectOptions copyWith({
    Locale? locale,
    List<ISpectActionItem>? actionItems,
    List<ISpectPanelItem>? panelItems,
    List<ISpectPanelButtonItem>? panelButtons,
    bool? isLogPageEnabled,
    bool? isPerformanceEnabled,
    bool? isInspectorEnabled,
    bool? isFeedbackEnabled,
    bool? isColorPickerEnabled,
    bool? isThemeSchemaEnabled,
    ISpectifyDataBuilder? itemsBuilder,
  }) =>
      ISpectOptions(
        locale: locale ?? this.locale,
        actionItems: actionItems ?? this.actionItems,
        panelItems: panelItems ?? this.panelItems,
        panelButtons: panelButtons ?? this.panelButtons,
        isLogPageEnabled: isLogPageEnabled ?? this.isLogPageEnabled,
        isPerformanceEnabled: isPerformanceEnabled ?? this.isPerformanceEnabled,
        isInspectorEnabled: isInspectorEnabled ?? this.isInspectorEnabled,
        isFeedbackEnabled: isFeedbackEnabled ?? this.isFeedbackEnabled,
        isColorPickerEnabled: isColorPickerEnabled ?? this.isColorPickerEnabled,
        isThemeSchemaEnabled: isThemeSchemaEnabled ?? this.isThemeSchemaEnabled,
        itemsBuilder: itemsBuilder ?? this.itemsBuilder,
      );
}
