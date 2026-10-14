import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/utils/copy_clipboard.dart';
import 'package:ispect/src/features/log_viewer/controllers/ispect_view_controller.dart';
import 'package:ispect/src/features/log_viewer/controllers/logs_view_pipeline.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

enum LogTypeFilterAction { toggle, showOnly, hide }

typedef LogTypeFilterCallback =
    void Function(String key, LogTypeFilterAction action);

/// Controller that encapsulates scroll tracking, keyboard navigation,
/// column resizing, type filtering, and relative time timer management
/// for the logs screen.
class LogsScreenController {
  LogsScreenController({
    required this.logsViewController,
    required this.logsScrollController,
    required this.searchFocusNode,
    required VoidCallback onStateChanged,
  }) : _onStateChanged = onStateChanged {
    keyboardFocusNode = FocusNode(debugLabel: 'DesktopLogKeyboard');
    listController = ListController();
    scrollDirection = ValueNotifier<bool?>(null);
    hasNewLogs = ValueNotifier<bool>(false);
    liveTailActive = ValueNotifier<bool>(false);

    logsScrollController.addListener(_onScroll);
    searchFocusNode.addListener(_onSearchFocusChanged);
    logsViewController.addListener(_onControllerChanged);
  }

  final ISpectViewController logsViewController;
  final ScrollController logsScrollController;
  final FocusNode searchFocusNode;
  final VoidCallback _onStateChanged;

  late final FocusNode keyboardFocusNode;
  late final ListController listController;
  late final ValueNotifier<bool?> scrollDirection;
  late final ValueNotifier<bool> hasNewLogs;

  late final ValueNotifier<bool> liveTailActive;

  double typeColumnWidth = 100;
  double timeColumnWidth = 140;

  bool isLiveTailPaused = false;
  int lastLogCount = 0;

  Timer? _relativeTimeTimer;

  void dispose() {
    logsScrollController.removeListener(_onScroll);
    searchFocusNode.removeListener(_onSearchFocusChanged);
    logsViewController.removeListener(_onControllerChanged);
    scrollDirection.dispose();
    keyboardFocusNode.dispose();
    listController.dispose();
    hasNewLogs.dispose();
    liveTailActive.dispose();
    _relativeTimeTimer?.cancel();
    _relativeTimeTimer = null;
    relativeTimeTick.dispose();
  }

  // --- Scroll tracking ---

  void _onScroll() {
    final sc = logsScrollController;
    if (!sc.hasClients) return;
    final offset = sc.offset;
    final maxExtent = sc.position.maxScrollExtent;

    if (offset < 300) {
      scrollDirection.value = null;
    } else if (offset >= maxExtent - 50) {
      scrollDirection.value = true;
    } else {
      scrollDirection.value = false;
    }

    const activateThreshold = 50.0;
    const deactivateThreshold = 120.0;

    if (!isLiveTailPaused) {
      if (logsViewController.isNewestFirst) {
        if (offset <= activateThreshold) {
          liveTailActive.value = true;
          hasNewLogs.value = false;
        } else if (offset > deactivateThreshold) {
          liveTailActive.value = false;
        }
      } else {
        if (offset >= maxExtent - activateThreshold) {
          liveTailActive.value = true;
          hasNewLogs.value = false;
        } else if (offset < maxExtent - deactivateThreshold) {
          liveTailActive.value = false;
        }
      }
    }
  }

  void toggleLiveTailPause() {
    isLiveTailPaused = !isLiveTailPaused;
    if (isLiveTailPaused) {
      liveTailActive.value = false;
    }
    _onStateChanged();
  }

  void onFabPressed() {
    final sc = logsScrollController;
    final target = (scrollDirection.value ?? false)
        ? 0.0
        : sc.position.maxScrollExtent;
    sc.animateTo(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void scrollToNewest() {
    final sc = logsScrollController;
    if (!sc.hasClients) return;
    final target = logsViewController.isNewestFirst
        ? 0.0
        : sc.position.maxScrollExtent;
    sc.animateTo(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
    hasNewLogs.value = false;
  }

  // --- Column resizing ---

  void handleColumnResize(int column, double delta) {
    if (column == 0) {
      typeColumnWidth = (typeColumnWidth + delta).clamp(80, 200);
    } else if (column == 1) {
      timeColumnWidth = (timeColumnWidth + delta).clamp(80, 250);
    }
    _onStateChanged();
  }

  // --- Type filtering ---

  void handleTypeFilter(String key, LogTypeFilterAction action) {
    switch (action) {
      case LogTypeFilterAction.showOnly:
        logsViewController.setOnlyLogTypeKey(key);
      case LogTypeFilterAction.hide:
        logsViewController.hideLogTypeKey(key);
      case LogTypeFilterAction.toggle:
        final currentKeys = logsViewController.filter.logTypeKeys;
        if (currentKeys.length == 1 && currentKeys.first == key) {
          logsViewController.filter = logsViewController.filter.copyWith(
            logTypeKeys: <String>[],
          );
        } else {
          logsViewController.setOnlyLogTypeKey(key);
        }
    }
  }

  List<ISpectLogData>? _cachedSortedEntries;
  List<ISpectLogData>? _lastSortInput;
  int _sortedEntriesGeneration = -1;
  LogSortColumn? _lastSortColumn;
  LogSortDirection? _lastSortDirection;

  KeyEventResult handleKeyEvent(
    FocusNode node,
    KeyEvent event,
    LogsViewState state,
    BuildContext context,
  ) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final isMetaOrCtrl =
        HardwareKeyboard.instance.isMetaPressed ||
        HardwareKeyboard.instance.isControlPressed;

    // Ctrl/Cmd+K or "/" to focus search
    if ((isMetaOrCtrl && event.logicalKey == LogicalKeyboardKey.keyK) ||
        (!searchFocusNode.hasFocus &&
            event.logicalKey == LogicalKeyboardKey.slash)) {
      searchFocusNode.requestFocus();
      return KeyEventResult.handled;
    }

    // Cmd/Ctrl+C: copy selected log message
    if (isMetaOrCtrl && event.logicalKey == LogicalKeyboardKey.keyC) {
      final activeData = logsViewController.activeData;
      if (activeData != null) {
        final text = activeData.toExportMessageText();
        if (text.isNotEmpty) {
          copyClipboard(context, value: text);
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    }

    // Don't handle arrow/escape when search is focused
    if (searchFocusNode.hasFocus) {
      return KeyEventResult.ignored;
    }

    if (state.rowCount == 0) return KeyEventResult.ignored;

    final activeData = logsViewController.activeData;

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      if (logsViewController.detailData != null) {
        logsViewController.closeDetail();
        return KeyEventResult.handled;
      }
      if (activeData != null) {
        logsViewController.activeData = null;
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    // Enter: open detail panel for selected log
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (activeData != null) {
        logsViewController.openLogDetail(activeData);
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
        event.logicalKey == LogicalKeyboardKey.arrowUp) {
      final isDown = event.logicalKey == LogicalKeyboardKey.arrowDown;
      int targetVisualIndex;

      if (activeData == null) {
        targetVisualIndex = isDown ? 0 : state.rowCount - 1;
      } else {
        final currentVisualIndex = state.idToVisualIndex[activeData.id];
        if (currentVisualIndex == null) return KeyEventResult.ignored;

        targetVisualIndex = isDown
            ? currentVisualIndex + 1
            : currentVisualIndex - 1;
        if (targetVisualIndex < 0 || targetVisualIndex >= state.rowCount) {
          return KeyEventResult.handled;
        }
      }

      final nextEntry = switch (state.rowAt(targetVisualIndex)) {
        final NetworkTransaction tx => tx.response ?? tx.error ?? tx.request,
        final ISpectLogData log => log,
        _ => null,
      };
      if (nextEntry == null) return KeyEventResult.ignored;

      if (logsViewController.detailData != null) {
        logsViewController.selectAndFollowDetail(nextEntry);
      } else {
        logsViewController.activeData = nextEntry;
      }

      listController.animateToItem(
        index: targetVisualIndex,
        scrollController: logsScrollController,
        alignment: 0.5,
        duration: (_) => const Duration(milliseconds: 200),
        curve: (_) => Curves.easeOutCubic,
      );

      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  // --- Helper methods ---

  /// Applies column sorting if needed. Cached by input identity, generation,
  /// column, and direction.
  List<ISpectLogData> applySortingIfNeeded(List<ISpectLogData> entries) {
    final column = logsViewController.sortColumn;
    if (column == LogSortColumn.time) return entries;

    final generation = logsViewController.outputGeneration;
    final direction = logsViewController.sortDirection;

    if (identical(_lastSortInput, entries) &&
        _sortedEntriesGeneration == generation &&
        _lastSortColumn == column &&
        _lastSortDirection == direction &&
        _cachedSortedEntries != null) {
      return _cachedSortedEntries!;
    }

    final sorted = logsViewController.applySorting(entries);
    _cachedSortedEntries = sorted;
    _lastSortInput = entries;
    _sortedEntriesGeneration = generation;
    _lastSortColumn = column;
    _lastSortDirection = direction;
    return sorted;
  }

  /// Get the log entry at a visual index, accounting for sort order.
  ISpectLogData getEntryAtVisualIndex(
    List<ISpectLogData> sortedEntries,
    int index,
  ) {
    if (logsViewController.sortColumn == LogSortColumn.time) {
      final result = logsViewController.getLogEntryAtIndex(
        sortedEntries,
        index,
      );
      if (result != null) return result.entry;
    }
    return sortedEntries[index];
  }

  // --- Relative time timer ---

  /// Advances every five seconds while relative timestamps are shown, so
  /// only the rows listening to it re-render instead of the whole screen.
  final ValueNotifier<int> relativeTimeTick = ValueNotifier<int>(0);

  void _onControllerChanged() {
    if (logsViewController.useRelativeTime) {
      _relativeTimeTimer ??= Timer.periodic(
        const Duration(seconds: 5),
        (_) => relativeTimeTick.value++,
      );
    } else {
      _relativeTimeTimer?.cancel();
      _relativeTimeTimer = null;
    }
    _onStateChanged();
  }

  void _onSearchFocusChanged() {
    if (!searchFocusNode.hasFocus && keyboardFocusNode.canRequestFocus) {
      keyboardFocusNode.requestFocus();
    }
  }

  // --- Live tail ---

  void checkForNewLogs(
    int rawCount, {
    required bool isDesktop,
    required VoidCallback onMount,
  }) {
    if (rawCount == lastLogCount) return;
    final hasNewLogsArrived = rawCount > lastLogCount && lastLogCount > 0;
    lastLogCount = rawCount;
    if (!isDesktop || !hasNewLogsArrived) return;
    if (liveTailActive.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) => onMount());
    } else {
      hasNewLogs.value = true;
    }
  }
}
