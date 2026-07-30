import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/controllers/export_controller.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/models/export_format.dart';
import 'package:ispect/src/common/observers/route_sanitizer.dart';
import 'package:ispect/src/common/observers/transition.dart';
import 'package:ispect/src/common/widgets/export_sheet.dart';

class ISpectNavigationFlowActionsSheet {
  const ISpectNavigationFlowActionsSheet({
    required this.log,
    required this.transition,
    required this.items,
  });

  final ISpectLogData? log;
  final RouteTransition? transition;
  final List<RouteTransition> items;

  Future<void> show(BuildContext context) {
    final shareCallback = context.iSpect.options.onShare;
    final controller = ExportController(
      availableFormats: ExportFormat.values,
      onShare: shareCallback,
    );

    return ISpectExportSheet.show(
      context,
      controller: controller,
      icon: Icons.route_rounded,
      contentBuilder: (format, {required action, redactKeys}) => Future.value(
        buildContent(
          transition: transition,
          items: items,
          format: format,
          action: action,
          redactKeys: redactKeys,
        ),
      ),
    );
  }

  @visibleForTesting
  static String buildContent({
    required RouteTransition? transition,
    required List<RouteTransition> items,
    required ExportFormat format,
    required ExportAction action,
    Set<String>? redactKeys,
    bool enableRedaction = true,
    RedactionService? redactionService,
  }) {
    final isTruncated = action == ExportAction.copy;
    final redactionActive = enableRedaction && ISpectRedaction.enabled;
    final redactor = redactionActive
        ? ISpectRedaction.resolveService(
            service: redactionService,
            sensitiveKeys: redactKeys,
          )
        : null;
    final rawText = transition != null && isTruncated
        ? _buildTruncatedPath(
            transition: transition,
            items: items,
            redactionActive: redactionActive,
          )
        : _buildHistory(
            items,
            redactionActive: redactionActive,
          );
    final text = _redactAndBound(
      rawText,
      redactor: redactor,
    );

    switch (format) {
      case ExportFormat.json:
      case ExportFormat.text:
      case ExportFormat.csv:
        return text;
      case ExportFormat.markdown:
        return _formatMarkdown(text);
    }
  }

  static String _buildHistory(
    List<RouteTransition> items, {
    required bool redactionActive,
  }) {
    final output = _BoundedNavigationBuffer(
      maxBytes: _maxNavigationOutputBytes,
      replaceOversizedDiagnostics: redactionActive,
    );
    final Iterator<RouteTransition> iterator;
    try {
      iterator = items.iterator;
    } catch (_) {
      return JsonValueNormalizer.unprintableValue;
    }

    RouteTransition? pending;
    var retained = 0;
    while (retained < _maxSourceItems && !output.isExhausted) {
      final bool hasNext;
      try {
        hasNext = iterator.moveNext();
      } catch (_) {
        if (pending != null) {
          _writeTransition(
            output,
            pending,
            index: retained - 1,
            isLast: false,
            redactionActive: redactionActive,
          );
        }
        output.writeTruncationMarker(
          marker: JsonValueNormalizer.unprintableValue,
        );
        return output.toString();
      }
      if (!hasNext) {
        if (pending == null) return 'No transitions recorded';
        _writeTransition(
          output,
          pending,
          index: retained - 1,
          isLast: true,
          redactionActive: redactionActive,
        );
        return output.toString();
      }

      final RouteTransition current;
      try {
        current = iterator.current;
      } catch (_) {
        output.writeTruncationMarker(
          marker: JsonValueNormalizer.unprintableValue,
        );
        return output.toString();
      }

      if (pending != null) {
        _writeTransition(
          output,
          pending,
          index: retained - 1,
          isLast: false,
          redactionActive: redactionActive,
        );
      }
      pending = current;
      retained++;
    }

    if (pending != null && !output.isExhausted) {
      _writeTransition(
        output,
        pending,
        index: retained - 1,
        isLast: false,
        redactionActive: redactionActive,
      );
      output.writeTruncationMarker();
    }
    return output.toString();
  }

  static String _buildTruncatedPath({
    required RouteTransition transition,
    required List<RouteTransition> items,
    required bool redactionActive,
  }) {
    final targetId = _comparableTransitionId(transition);
    if (targetId == null) return JsonValueNormalizer.unprintableValue;

    final int itemCount;
    try {
      itemCount = items.length;
    } catch (_) {
      return JsonValueNormalizer.unprintableValue;
    }
    if (itemCount <= 0) return 'Transition not found';

    final output = _BoundedNavigationBuffer(
      maxBytes: _maxNavigationOutputBytes,
      replaceOversizedDiagnostics: redactionActive,
    );
    String? lastAdded;
    var inspected = 0;
    var found = false;
    for (var index = itemCount - 1;
        index >= 0 && inspected < _maxSourceItems && !output.isExhausted;
        index--) {
      final RouteTransition current;
      try {
        current = items[index];
      } catch (_) {
        output.writeTruncationMarker(
          marker: JsonValueNormalizer.unprintableValue,
        );
        return output.toString();
      }
      inspected++;

      final fromName = _routeName(
        _transitionMetadata(current, from: true),
        redactionActive: redactionActive,
      );
      final toName = _routeName(
        _transitionMetadata(current, from: false),
        redactionActive: redactionActive,
      );
      if (lastAdded == null) {
        output.writeDiagnostic(fromName);
        lastAdded = fromName;
      }
      if (lastAdded != toName) {
        output
          ..writeStatic(' → ')
          ..writeDiagnostic(toName);
        lastAdded = toName;
      }

      final currentId = _comparableTransitionId(current);
      if (currentId != null && currentId == targetId) {
        found = true;
        break;
      }
    }

    if (found) return output.toString();
    if (inspected >= _maxSourceItems || output.isExhausted) {
      output.writeTruncationMarker();
      return output.toString();
    }
    return 'Transition not found';
  }

  static void _writeTransition(
    _BoundedNavigationBuffer output,
    RouteTransition transition, {
    required int index,
    required bool isLast,
    required bool redactionActive,
  }) {
    if (index == 0) {
      output.writeStatic('Current: \n');
    } else if (isLast) {
      output.writeStatic('Start: \n');
    } else {
      output.writeStatic('\n');
    }
    output
      ..writeStatic(_timestampText(transition))
      ..writeStatic('\n');

    final fromName = _routeName(
      _transitionMetadata(transition, from: true),
      redactionActive: redactionActive,
    );
    final toName = _routeName(
      _transitionMetadata(transition, from: false),
      redactionActive: redactionActive,
    );
    output
      ..writeDiagnostic(fromName)
      ..writeStatic(' → ')
      ..writeDiagnostic(toName)
      ..writeStatic(' (')
      ..writeStatic(_transitionTypeTitle(transition))
      ..writeStatic(')\n');

    final arguments = _transitionArguments(transition);
    if (arguments.available && arguments.value != null) {
      output
        ..writeStatic('Arguments: ')
        ..writeDiagnostic(
          _argumentsText(
            arguments.value,
            redactionActive: redactionActive,
          ),
        )
        ..writeStatic('\n');
    } else if (!arguments.available) {
      output
        ..writeStatic('Arguments: ')
        ..writeStatic(JsonValueNormalizer.unprintableValue)
        ..writeStatic('\n');
    }
    output.writeStatic('\n${ConsoleUtils.bottomLine(20)}\n');
  }

  static RouteMetadata? _transitionMetadata(
    RouteTransition transition, {
    required bool from,
  }) {
    try {
      return from ? transition.from : transition.to;
    } catch (_) {
      return const RouteMetadata(
        name: JsonValueNormalizer.unprintableValue,
        routeType: JsonValueNormalizer.unprintableValue,
      );
    }
  }

  static ({bool available, Object? value}) _transitionArguments(
    RouteTransition transition,
  ) {
    try {
      return (available: true, value: transition.arguments);
    } catch (_) {
      return (available: false, value: null);
    }
  }

  static String _routeName(
    RouteMetadata? metadata, {
    required bool redactionActive,
  }) {
    if (metadata == null) return 'Unknown';
    final String name;
    try {
      name = metadata.name;
    } catch (_) {
      return JsonValueNormalizer.unprintableValue;
    }
    final prepared = _prepareSourceString(
      name,
      redactionActive: redactionActive,
    );
    if (prepared == LogExportOutput.truncatedMarker) return prepared;
    if (!redactionActive) return prepared;
    try {
      return sanitizeRouteDiagnosticName(
        prepared,
        resourceLimits: _resourceLimits,
      );
    } catch (_) {
      return defaultPlaceholder;
    }
  }

  static String _argumentsText(
    Object? arguments, {
    required bool redactionActive,
  }) {
    if (redactionActive) {
      if (arguments == null) return '';
      return _prepareSourceString(
        summarizeRouteDiagnosticArguments(arguments),
        redactionActive: true,
      );
    }

    final snapshot = LogExportOutput.boundJsonValue(arguments);
    if (snapshot is String) return snapshot;
    if (snapshot == null) return '';
    if (snapshot is bool || snapshot is num) {
      return snapshot.toString();
    }
    try {
      return _prepareSourceString(
        jsonEncode(snapshot),
        redactionActive: false,
      );
    } catch (_) {
      return JsonValueNormalizer.unprintableValue;
    }
  }

  static String _timestampText(RouteTransition transition) {
    try {
      final timestamp = transition.timestamp;
      final snapshot = DateTime.fromMicrosecondsSinceEpoch(
        timestamp.microsecondsSinceEpoch,
        isUtc: timestamp.isUtc,
      );
      return '${_twoDigits(snapshot.day)}.'
          '${_twoDigits(snapshot.month)}.'
          '${_twoDigits(snapshot.year % 100)}, '
          '${_twoDigits(snapshot.hour)}:'
          '${_twoDigits(snapshot.minute)}:'
          '${_twoDigits(snapshot.second)}';
    } catch (_) {
      return JsonValueNormalizer.unprintableValue;
    }
  }

  static String _transitionTypeTitle(RouteTransition transition) {
    try {
      return transition.type.title;
    } catch (_) {
      return JsonValueNormalizer.unprintableValue;
    }
  }

  static String? _comparableTransitionId(RouteTransition transition) {
    try {
      final id = transition.id;
      final maxBytes = _resourceLimits.maxCapturedValueBytes;
      if (LogExportOutput.utf8Length(
            id,
            limit: maxBytes,
          ) >
          maxBytes) {
        return null;
      }
      return id;
    } catch (_) {
      return null;
    }
  }

  static String _prepareSourceString(
    String value, {
    required bool redactionActive,
  }) {
    final maxBytes = _resourceLimits.maxCapturedValueBytes;
    if (LogExportOutput.utf8Length(value, limit: maxBytes) <= maxBytes) {
      return value;
    }
    if (redactionActive) return LogExportOutput.truncatedMarker;
    return LogExportOutput.truncateUtf8(value, maxBytes: maxBytes);
  }

  static String _redactAndBound(
    String rawText, {
    required RedactionService? redactor,
  }) {
    final safeText =
        redactor == null ? rawText : _redactedText(rawText, redactor);
    return LogExportOutput.truncateUtf8(
      safeText,
      maxBytes: _maxNavigationOutputBytes,
    );
  }

  static String _redactedText(String rawText, RedactionService redactor) {
    try {
      final redacted = redactor.redactForExport(
        rawText,
        resourceLimits: _resourceLimits,
      );
      return redacted is String ? redacted : defaultPlaceholder;
    } catch (_) {
      return defaultPlaceholder;
    }
  }

  static String _formatMarkdown(String text) {
    final fence = _safeMarkdownFence(text);
    if (fence == null) return _markdownFallback;

    final prefix = '# Navigation Flow\n\n$fence\n';
    final suffix = '\n$fence\n';
    final framingBytes =
        LogExportOutput.utf8Length(prefix) + LogExportOutput.utf8Length(suffix);
    if (framingBytes > _maxNavigationOutputBytes) return _markdownFallback;

    final body = LogExportOutput.truncateUtf8(
      text,
      maxBytes: _maxNavigationOutputBytes - framingBytes,
    );
    return '$prefix$body$suffix';
  }

  static String? _safeMarkdownFence(String value) {
    final backtickLength = _requiredFenceLength(value, 0x60);
    final tildeLength = _requiredFenceLength(value, 0x7e);
    final useBackticks = backtickLength <= tildeLength;
    final length = useBackticks ? backtickLength : tildeLength;
    if (length * 2 + 32 > _maxNavigationOutputBytes) return null;
    return ''.padLeft(length, useBackticks ? '`' : '~');
  }

  static int _requiredFenceLength(String value, int fenceCodeUnit) {
    var longestRun = 0;
    var currentRun = 0;
    for (final codeUnit in value.codeUnits) {
      if (codeUnit == fenceCodeUnit) {
        currentRun++;
        if (currentRun > longestRun) longestRun = currentRun;
      } else {
        currentRun = 0;
      }
    }
    return longestRun < 3 ? 3 : longestRun + 1;
  }

  static String _twoDigits(int value) => value.toString().padLeft(2, '0');

  static DiagnosticResourceLimits get _resourceLimits =>
      (ISpect.loggerIfInitialized?.options.resourceLimits ??
          DiagnosticResourceLimits.balanced)
        ..validate();

  static int get _maxSourceItems => _resourceLimits.maxCollectionItems;

  static int get _maxNavigationOutputBytes {
    final limits = _resourceLimits;
    return limits.maxLogRecordBytes < limits.maxExportDocumentBytes
        ? limits.maxLogRecordBytes
        : limits.maxExportDocumentBytes;
  }

  static const String _markdownFallback = '# Navigation Flow\n\n```\n'
      '${LogExportOutput.truncatedMarker}\n'
      '```\n';
}

final class _BoundedNavigationBuffer {
  _BoundedNavigationBuffer({
    required this.maxBytes,
    required this.replaceOversizedDiagnostics,
  });

  final int maxBytes;
  final bool replaceOversizedDiagnostics;
  final StringBuffer _buffer = StringBuffer();
  int _bytes = 0;
  bool _sealed = false;

  bool get isExhausted => _sealed || _bytes >= maxBytes;

  void writeStatic(String value) {
    if (isExhausted || value.isEmpty) return;
    final remaining = maxBytes - _bytes;
    final bounded = LogExportOutput.truncateUtf8(
      value,
      maxBytes: remaining,
    );
    _buffer.write(bounded);
    _bytes += LogExportOutput.utf8Length(bounded);
    if (bounded.length != value.length) _sealed = true;
  }

  void writeDiagnostic(String value) {
    if (isExhausted || value.isEmpty) return;
    final remaining = maxBytes - _bytes;
    if (LogExportOutput.utf8Length(value, limit: remaining) <= remaining) {
      _buffer.write(value);
      _bytes += LogExportOutput.utf8Length(value);
      return;
    }
    if (replaceOversizedDiagnostics) {
      writeTruncationMarker();
      return;
    }
    final bounded = LogExportOutput.truncateUtf8(
      value,
      maxBytes: remaining,
    );
    _buffer.write(bounded);
    _bytes += LogExportOutput.utf8Length(bounded);
    _sealed = true;
  }

  void writeTruncationMarker({
    String marker = LogExportOutput.truncatedMarker,
  }) {
    if (isExhausted) return;
    final remaining = maxBytes - _bytes;
    final bounded = LogExportOutput.truncateUtf8(
      marker,
      maxBytes: remaining,
      marker: '',
    );
    _buffer.write(bounded);
    _bytes += LogExportOutput.utf8Length(bounded);
    _sealed = true;
  }

  @override
  String toString() => _buffer.toString();
}
