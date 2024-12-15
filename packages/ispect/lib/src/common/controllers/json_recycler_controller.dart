import 'package:flutter/material.dart';
import 'package:ispect/src/core/res/json_color.dart';

class JsonRecyclerController {
  JsonRecyclerController({
    required this.isExpanded,
    this.saveClosedHistory = true,
    this.showStandardJson = false,
    this.jsonKeyColor = JsonColors.jsonKeyColor,
    this.intColor = JsonColors.intColor,
    this.doubleColor = JsonColors.doubleColor,
    this.stringColor = JsonColors.stringColor,
    this.nullColor = JsonColors.nullColor,
    this.boolColor = JsonColors.boolColor,
    this.objectColor = JsonColors.objectColor,
    this.standardJsonBackgroundColor = JsonColors.jsonBackgroundColor,
    this.iconOpened = const Icon(Icons.arrow_drop_down),
    this.iconClosed = const Icon(Icons.arrow_right),
    this.fontWeight = FontWeight.bold,
    this.horizontalSpaceMultiplier = 18,
    this.verticalOffset = 4,
    this.additionalIndentChildElements = 6,
    this.fontStyle,
  });

  final bool saveClosedHistory;
  final bool showStandardJson;
  bool isExpanded = false;

  final Color jsonKeyColor;
  final Color intColor;
  final Color doubleColor;
  final Color stringColor;
  final Color nullColor;
  final Color boolColor;
  final Color objectColor;
  final Color standardJsonBackgroundColor;
  final Widget iconOpened;
  final Widget iconClosed;
  final FontWeight fontWeight;
  final double verticalOffset;
  final double horizontalSpaceMultiplier;

  /// Additional indentation for aligning child elements
  /// depending on the size of the parent icon
  final double additionalIndentChildElements;

  final FontStyle? fontStyle;

  void changeState() {
    isExpanded = !isExpanded;
  }

  JsonRecyclerController copyWith({
    bool? saveClosedHistory,
    bool? showStandardJson,
    bool? isExpanded,
    Color? jsonKeyColor,
    Color? intColor,
    Color? doubleColor,
    Color? stringColor,
    Color? nullColor,
    Color? boolColor,
    Color? objectColor,
    Color? standardJsonBackgroundColor,
    Widget? iconOpened,
    Widget? iconClosed,
    FontWeight? fontWeight,
    double? verticalOffset,
    double? horizontalSpaceMultiplier,
    double? additionalIndentChildElements,
    FontStyle? fontStyle,
  }) =>
      JsonRecyclerController(
        saveClosedHistory: saveClosedHistory ?? this.saveClosedHistory,
        showStandardJson: showStandardJson ?? this.showStandardJson,
        isExpanded: isExpanded ?? this.isExpanded,
        jsonKeyColor: jsonKeyColor ?? this.jsonKeyColor,
        intColor: intColor ?? this.intColor,
        doubleColor: doubleColor ?? this.doubleColor,
        stringColor: stringColor ?? this.stringColor,
        nullColor: nullColor ?? this.nullColor,
        boolColor: boolColor ?? this.boolColor,
        objectColor: objectColor ?? this.objectColor,
        standardJsonBackgroundColor:
            standardJsonBackgroundColor ?? this.standardJsonBackgroundColor,
        iconOpened: iconOpened ?? this.iconOpened,
        iconClosed: iconClosed ?? this.iconClosed,
        fontWeight: fontWeight ?? this.fontWeight,
        verticalOffset: verticalOffset ?? this.verticalOffset,
        horizontalSpaceMultiplier:
            horizontalSpaceMultiplier ?? this.horizontalSpaceMultiplier,
        additionalIndentChildElements:
            additionalIndentChildElements ?? this.additionalIndentChildElements,
        fontStyle: fontStyle ?? this.fontStyle,
      );
}
