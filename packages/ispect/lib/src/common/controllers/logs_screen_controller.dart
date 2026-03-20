import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/controllers/group_button.dart';
import 'package:ispect/src/common/controllers/ispect_view_controller.dart';
import 'package:ispect/src/common/utils/copy_clipboard.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

/// Controller that encapsulates scroll tracking, keyboard navigation,
/// column resizing, type filtering, and relative time timer management
/// for the logs screen.
class LogsScreenController {
  LogsScreenController({
    required this.logsViewController,
    required this.logsScrollController,
    required this.searchFocusNode,
    required this.titleFiltersController,
    required VoidCallback onStateChanged,
  }) : _onStateChanged = onStateChanged {
    keyboardFocusNode = FocusNode(debugLabel: 'DesktopLogKeyboard');
    listController = ListController();
    scrollDirection = ValueNotifier<bool?>(null);
    hasNewLogs = ValueNotifier<bool>(false);

    logsScrollController.addListener(_onScroll);
    searchFocusNode.addListener(_onSearchFocusChanged);
    logsViewController.addListener(_onControllerChanged);
  }

  final ISpectViewController logsViewController;
  final ScrollController logsScrollController;
  final FocusNode searchFocusNode;
  final GroupButtonController titleFiltersController;
  final VoidCallback _onStateChanged;

  late final FocusNode keyboardFocusNode;
  late final ListController listController;
  late final ValueNotifier<bool?> scrollDirection;
  late final ValueNotifier<bool> hasNewLogs;

  double typeColumnWidth = 100;
  double timeColumnWidth = 140;

  bool isLiveTailActive = false;
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
    _relativeTimeTimer?.cancel();
    _relativeTimeTimer = null;
  }

  // --- Scroll tracking ---

  /// Whether newest logs appear at scroll offset 0 (top).
  bool get isNewestAtTop {
    final vc = logsViewController;
    return vc.sortColumn == LogSortColumn.time && vc.isLogOrderReversed;
  }

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
      if (isNewestAtTop) {
        if (offset <= activateThreshold) {
          isLiveTailActive = true;
          hasNewLogs.value = false;
        } else if (offset > deactivateThreshold) {
          isLiveTailActive = false;
        }
      } else {
        if (offset >= maxExtent - activateThreshold) {
          isLiveTailActive = true;
          hasNewLogs.value = false;
        } else if (offset < maxExtent - deactivateThreshold) {
          isLiveTailActive = false;
        }
      }
    }
  }

  void toggleLiveTailPause() {
    isLiveTailPaused = !isLiveTailPaused;
    if (isLiveTailPaused) {
      isLiveTailActive = false;
    }
    _onStateChanged();
  }

  void onFabPressed() {
    final sc = logsScrollController;
    final target =
        (scrollDirection.value ?? false) ? 0.0 : sc.position.maxScrollExtent;
    sc.animateTo(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void scrollToNewest() {
    final sc = logsScrollController;
    if (!sc.hasClients) return;
    final target = isNewestAtTop ? 0.0 : sc.position.maxScrollExtent;
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

  void handleTypeFilter(String typeAction, List<ISpectLogData> logsData) {
    final titles = logsViewController.getTitles(logsData);
    final uniq = titles.unique;

    if (typeAction.startsWith('__show_only__')) {
      final type = typeAction.replaceFirst('__show_only__', '');
      logsViewController.setOnlyTitle(type);
      _syncChipsToFilter(type, uniq, showOnly: true);
      return;
    }
    if (typeAction.startsWith('__hide__')) {
      final type = typeAction.replaceFirst('__hide__', '');
      logsViewController.excludeTitle(type, uniq);
      _syncChipsToFilter(type, uniq, showOnly: false);
      return;
    }
    // Simple click on type: toggle
    final currentTitles = logsViewController.filter.titles;
    if (currentTitles.length == 1 && currentTitles.first == typeAction) {
      logsViewController.filter =
          logsViewController.filter.copyWith(titles: <String>[]);
      titleFiltersController.unselectAll();
    } else {
      logsViewController.setOnlyTitle(typeAction);
      _syncChipsToFilter(typeAction, uniq, showOnly: true);
    }
  }

  void _syncChipsToFilter(
    String type,
    List<String> uniqTitles, {
    required bool showOnly,
  }) {
    final controller = titleFiltersController..unselectAll();
    if (showOnly) {
      final idx = uniqTitles.indexOf(type);
      if (idx != -1) controller.selectIndex(idx);
    } else {
      for (var i = 0; i < uniqTitles.length; i++) {
        if (uniqTitles[i] != type) controller.selectIndex(i);
      }
    }
  }

  List<ISpectLogData>? _cachedSortedEntries;
  int _sortedEntriesGeneration = -1;
  LogSortColumn? _lastSortColumn;
  LogSortDirection? _lastSortDirection;

  List<ISpectLogData>? _cachedVisualEntries;
  List<ISpectLogData>? _lastVisualEntriesInput;
  bool _lastVisualEntriesReversed = false;

  KeyEventResult handleKeyEvent(
    FocusNode node,
    KeyEvent event,
    List<ISpectLogData> logsData,
    BuildContext context,
  ) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final isMetaOrCtrl = HardwareKeyboard.instance.isMetaPressed ||
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
        final text = activeData.isHttpLog
            ? (activeData.httpLogText ?? '')
            : activeData.textMessage;
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

    final filteredLogEntries = logsViewController.applyCurrentFilters(logsData);
    final sortedEntries = applySortingIfNeeded(filteredLogEntries);
    if (sortedEntries.isEmpty) return KeyEventResult.ignored;

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
      final visualEntries = getVisualEntries(sortedEntries);
      int targetVisualIndex;

      if (activeData == null) {
        targetVisualIndex = isDown ? 0 : visualEntries.length - 1;
      } else {
        final currentVisualIndex = visualEntries.indexOf(activeData);
        if (currentVisualIndex == -1) return KeyEventResult.ignored;

        targetVisualIndex =
            isDown ? currentVisualIndex + 1 : currentVisualIndex - 1;
        if (targetVisualIndex < 0 ||
            targetVisualIndex >= visualEntries.length) {
          return KeyEventResult.handled;
        }
      }

      final nextEntry = visualEntries[targetVisualIndex];

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

  /// Returns entries in visual display order. Cached by input identity + reverse state.
  List<ISpectLogData> getVisualEntries(List<ISpectLogData> sortedEntries) {
    final isReversed = logsViewController.sortColumn == LogSortColumn.time &&
        logsViewController.isLogOrderReversed;

    if (identical(sortedEntries, _lastVisualEntriesInput) &&
        _lastVisualEntriesReversed == isReversed &&
        _cachedVisualEntries != null) {
      return _cachedVisualEntries!;
    }

    final result =
        isReversed ? sortedEntries.reversed.toList() : sortedEntries;
    _cachedVisualEntries = result;
    _lastVisualEntriesInput = sortedEntries;
    _lastVisualEntriesReversed = isReversed;
    return result;
  }

  /// Applies column sorting if needed. Cached by generation + column + direction.
  List<ISpectLogData> applySortingIfNeeded(List<ISpectLogData> entries) {
    final column = logsViewController.sortColumn;
    if (column == LogSortColumn.time) return entries;

    final generation = logsViewController.outputGeneration;
    final direction = logsViewController.sortDirection;

    if (_sortedEntriesGeneration == generation &&
        _lastSortColumn == column &&
        _lastSortDirection == direction &&
        _cachedSortedEntries != null) {
      return _cachedSortedEntries!;
    }

    final sorted = logsViewController.applySorting(entries);
    _cachedSortedEntries = sorted;
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
      final result =
          logsViewController.getLogEntryAtIndex(sortedEntries, index);
      if (result != null) return result.entry;
    }
    return sortedEntries[index];
  }

  // --- Relative time timer ---

  void _onControllerChanged() {
    if (logsViewController.useRelativeTime) {
      _relativeTimeTimer ??= Timer.periodic(
        const Duration(seconds: 5),
        (_) => _onStateChanged(),
      );
    } else {
      _relativeTimeTimer?.cancel();
      _relativeTimeTimer = null;
    }
  }

  void _onSearchFocusChanged() {
    if (!searchFocusNode.hasFocus && keyboardFocusNode.canRequestFocus) {
      keyboardFocusNode.requestFocus();
    }
  }

  // --- Live tail ---

  /// Check for new logs and handle live tail auto-scroll.
  /// Returns true if state was updated and a rebuild is needed.
  void checkForNewLogs(
    int rawCount, {
    required bool isDesktop,
    required VoidCallback onMount,
  }) {
    if (isDesktop && rawCount != lastLogCount) {
      if (rawCount > lastLogCount && lastLogCount > 0) {
        if (isLiveTailActive) {
          WidgetsBinding.instance.addPostFrameCallback((_) => onMount());
        } else {
          hasNewLogs.value = true;
        }
      }
      lastLogCount = rawCount;
    }
  }
}
