// This benchmark intentionally profiles the internal widgets used by LogsScreen.
// ignore_for_file: implementation_imports

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/widgets/ispect_theme_scope.dart';
import 'package:ispect/src/features/log_viewer/controllers/group_button.dart';
import 'package:ispect/src/features/log_viewer/controllers/ispect_view_controller.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/logs_builder.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/logs_viewer_body.dart';

const highVolumeEventCount = 2000;
const _highVolumeErrorStride = 10;
const highVolumeErrorCount =
    (highVolumeEventCount + _highVolumeErrorStride - 1) ~/
        _highVolumeErrorStride;

final class HighVolumeBenchmarkApp extends StatefulWidget {
  const HighVolumeBenchmarkApp({super.key});

  @override
  State<HighVolumeBenchmarkApp> createState() => HighVolumeBenchmarkState();
}

final class HighVolumeBenchmarkState extends State<HighVolumeBenchmarkApp> {
  final _logger = ISpectLogger(
    options: ISpectLoggerOptions(
      useConsoleLogs: false,
      maxHistoryItems: highVolumeEventCount,
    ),
  );
  final _scope = ISpectScopeModel(
    isISpectEnabled: true,
    options: const ISpectOptions(),
  );
  final _viewController = ISpectViewController(groupHttpLogs: false);
  final _titleFiltersController = GroupButtonController();
  final _searchFocusNode = FocusNode();
  final _logsScrollController = ScrollController();

  int get totalLogCount => _logger.history.length;

  int get visibleLogCount =>
      _viewController.applyFiltersWithoutSearch(_logger.history).length;

  Set<String> get activeLogTypeKeys =>
      Set<String>.unmodifiable(_viewController.filter.logTypeKeys);

  double get refreshRate => View.of(context).display.refreshRate;

  Size get physicalSize => View.of(context).physicalSize;

  double get devicePixelRatio => View.of(context).devicePixelRatio;

  void seedEvents() {
    if (_logger.history.isNotEmpty) {
      throw StateError('High-volume benchmark events are already seeded');
    }

    final startedAt = DateTime.utc(2026);
    for (var index = 0; index < highVolumeEventCount; index++) {
      final isError = index % _highVolumeErrorStride == 0;
      _logger.logData(
        ISpectLogData(
          'Synthetic benchmark event $index',
          id: 'benchmark-${index.toString().padLeft(16, '0')}',
          key: isError ? ISpectLogType.error.key : ISpectLogType.info.key,
          logLevel: isError ? LogLevel.error : LogLevel.info,
          time: startedAt.add(Duration(milliseconds: index)),
          additionalData: <String, dynamic>{
            'event-index': index,
            'scenario': 'high-volume-profile',
          },
        ),
      );
    }
  }

  void showErrorsOnly() {
    _viewController.setOnlyLogTypeKey(ISpectLogType.error.key);
  }

  void showAllLogs() {
    _viewController.clearAllFilters();
    _titleFiltersController.unselectAll();
  }

  void resetScrollPosition() {
    if (!_logsScrollController.hasClients) return;
    _logsScrollController.jumpTo(
      _logsScrollController.position.minScrollExtent,
    );
  }

  @override
  void dispose() {
    _logsScrollController.dispose();
    _searchFocusNode.dispose();
    _titleFiltersController.dispose();
    _viewController.dispose();
    _scope.dispose();
    unawaited(_logger.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ISpectScopeController(
        model: _scope,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          localizationsDelegates: ISpectLocalization.localizationDelegates,
          supportedLocales: ISpectLocalization.supportedLocales,
          home: Scaffold(
            body: ISpectThemeScope(
              child: Builder(
                builder: (context) => ISpectLogsBuilder(
                  logger: _logger,
                  controller: _viewController,
                  builder: (_, logs) => LogsViewerBody(
                    logsData: logs,
                    controller: _viewController,
                    iSpectTheme: ISpect.read(context),
                    titleFiltersController: _titleFiltersController,
                    searchFocusNode: _searchFocusNode,
                    logsScrollController: _logsScrollController,
                    appBarTitle: 'High-volume benchmark',
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
