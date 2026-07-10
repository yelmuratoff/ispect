// ignore_for_file: avoid_unused_constructor_parameters

import 'dart:async';

import 'package:ispectify/ispectify.dart';

final class RollingFileLogHistory implements FileLogHistory {
  RollingFileLogHistory(
    ISpectLoggerOptions loggerOptions, {
    required FileLogDirectoryProvider directoryProvider,
    FileLogHistoryOptions options = const FileLogHistoryOptions(),
    RedactionService? redactor,
  }) {
    throw UnsupportedError('File log history requires dart:io');
  }

  RollingFileLogHistory.testing(
    ISpectLoggerOptions loggerOptions, {
    required FileLogDirectoryProvider directoryProvider,
    FileLogHistoryOptions options = const FileLogHistoryOptions(),
    RedactionService? redactor,
    Timer Function(Duration, void Function())? timerFactory,
  }) {
    throw UnsupportedError('File log history requires dart:io');
  }

  Never _unsupported() =>
      throw UnsupportedError('File log history requires dart:io');

  @override
  List<ISpectLogData> get history => _unsupported();

  @override
  String get sessionDirectory => _unsupported();

  @override
  String get todaySessionPath => _unsupported();

  @override
  void add(ISpectLogData data) => _unsupported();

  @override
  void clear() => _unsupported();

  @override
  void dispose() => _unsupported();

  @override
  Future<void> saveToDailyFile() => _unsupported();

  @override
  Future<void> loadFromDate(DateTime date) => _unsupported();

  @override
  Future<void> loadTodayHistory() => _unsupported();

  @override
  Future<String> exportToJson() => _unsupported();

  @override
  Future<void> importFromJson(String jsonString) => _unsupported();

  @override
  Future<void> clearAllFileStorage() => _unsupported();

  @override
  Future<void> clearDateStorage(DateTime date) => _unsupported();

  @override
  Future<List<DateTime>> getAvailableLogDates() => _unsupported();

  @override
  Future<int> getDateFileSize(DateTime date) => _unsupported();

  @override
  Future<bool> hasTodaySession() => _unsupported();

  @override
  Future<List<ISpectLogData>> getLogsByDate(DateTime date) => _unsupported();

  @override
  Future<String> getLogPathByDate(DateTime date) => _unsupported();

  @override
  Future<List<ISpectLogData>> getLogsBySession(String sessionPath) =>
      _unsupported();

  @override
  Future<SessionStatistics> getSessionStatistics() => _unsupported();

  @override
  void updateAutoSaveSettings({bool? enabled, Duration? interval}) =>
      _unsupported();
}
