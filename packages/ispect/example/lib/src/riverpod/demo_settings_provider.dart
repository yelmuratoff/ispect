import 'package:flutter_riverpod/flutter_riverpod.dart';

class DemoSettings {
  final int requestCount;
  final int itemCount;
  final int nestingDepth;
  final int payloadSize;
  final bool enableHttp;
  final bool enableWs;
  final bool enableLogging;
  final bool enableExceptions;
  final bool enableFileUploads;
  final bool enableAnalytics;
  final bool enableBlocEvents;
  final bool enableRoutes;
  final bool enableRiverpod;
  final bool httpSendSuccess;
  final bool httpSendErrors;
  final String httpMethod;
  final bool useAuthHeader;
  final int wsMessageSize;
  final int loopDelayMs;
  final bool randomize;
  final String preset;
  final bool streamMode;
  final int streamIntervalMs;

  const DemoSettings({
    this.requestCount = 1,
    this.itemCount = 100,
    this.nestingDepth = 3,
    this.payloadSize = 64,
    this.enableHttp = true,
    this.enableWs = false,
    this.enableLogging = true,
    this.enableExceptions = false,
    this.enableFileUploads = false,
    this.enableAnalytics = false,
    this.enableBlocEvents = false,
    this.enableRoutes = false,
    this.enableRiverpod = false,
    this.httpSendSuccess = true,
    this.httpSendErrors = true,
    this.httpMethod = 'GET',
    this.useAuthHeader = false,
    this.wsMessageSize = 16,
    this.loopDelayMs = 0,
    this.randomize = false,
    this.preset = 'Custom',
    this.streamMode = false,
    this.streamIntervalMs = 1000,
  });

  DemoSettings copyWith({
    int? requestCount,
    int? itemCount,
    int? nestingDepth,
    int? payloadSize,
    bool? enableHttp,
    bool? enableWs,
    bool? enableLogging,
    bool? enableExceptions,
    bool? enableFileUploads,
    bool? enableAnalytics,
    bool? enableBlocEvents,
    bool? enableRoutes,
    bool? enableRiverpod,
    bool? httpSendSuccess,
    bool? httpSendErrors,
    String? httpMethod,
    bool? useAuthHeader,
    int? wsMessageSize,
    int? loopDelayMs,
    bool? randomize,
    String? preset,
    bool? streamMode,
    int? streamIntervalMs,
  }) {
    return DemoSettings(
      requestCount: requestCount ?? this.requestCount,
      itemCount: itemCount ?? this.itemCount,
      nestingDepth: nestingDepth ?? this.nestingDepth,
      payloadSize: payloadSize ?? this.payloadSize,
      enableHttp: enableHttp ?? this.enableHttp,
      enableWs: enableWs ?? this.enableWs,
      enableLogging: enableLogging ?? this.enableLogging,
      enableExceptions: enableExceptions ?? this.enableExceptions,
      enableFileUploads: enableFileUploads ?? this.enableFileUploads,
      enableAnalytics: enableAnalytics ?? this.enableAnalytics,
      enableBlocEvents: enableBlocEvents ?? this.enableBlocEvents,
      enableRoutes: enableRoutes ?? this.enableRoutes,
      enableRiverpod: enableRiverpod ?? this.enableRiverpod,
      httpSendSuccess: httpSendSuccess ?? this.httpSendSuccess,
      httpSendErrors: httpSendErrors ?? this.httpSendErrors,
      httpMethod: httpMethod ?? this.httpMethod,
      useAuthHeader: useAuthHeader ?? this.useAuthHeader,
      wsMessageSize: wsMessageSize ?? this.wsMessageSize,
      loopDelayMs: loopDelayMs ?? this.loopDelayMs,
      randomize: randomize ?? this.randomize,
      preset: preset ?? this.preset,
      streamMode: streamMode ?? this.streamMode,
      streamIntervalMs: streamIntervalMs ?? this.streamIntervalMs,
    );
  }
}

class DemoSettingsNotifier extends StateNotifier<DemoSettings> {
  DemoSettingsNotifier() : super(const DemoSettings());

  void updateSettings(DemoSettings newSettings) {
    state = newSettings;
  }

  void applyPreset(String preset, Map<String, dynamic> config) {
    state = state.copyWith(
      requestCount: config['requestCount'] as int,
      itemCount: config['itemCount'] as int,
      nestingDepth: config['nestingDepth'] as int,
      payloadSize: config['payloadSize'] as int,
      enableHttp: config['enableHttp'] as bool,
      enableWs: config['enableWs'] as bool,
      enableLogging: config['enableLogging'] as bool,
      enableExceptions: config['enableExceptions'] as bool,
      enableFileUploads: config['enableFileUploads'] as bool,
      enableAnalytics: config['enableAnalytics'] as bool,
      enableBlocEvents: config['enableBlocEvents'] as bool,
      enableRoutes: config['enableRoutes'] as bool,
      enableRiverpod: config['enableRiverpod'] as bool,
      httpMethod: config['httpMethod'] as String,
      useAuthHeader: config['useAuthHeader'] as bool,
      httpSendSuccess: config['httpSendSuccess'] as bool,
      httpSendErrors: config['httpSendErrors'] as bool,
      wsMessageSize: config['wsMessageSize'] as int,
      loopDelayMs: config['loopDelayMs'] as int,
      randomize: config['randomize'] as bool,
      preset: preset,
    );
  }

  void reset() {
    state = const DemoSettings();
  }

  // Individual update methods
  void updateRequestCount(int value) =>
      state = state.copyWith(requestCount: value);
  void updateItemCount(int value) => state = state.copyWith(itemCount: value);
  void updateNestingDepth(int value) =>
      state = state.copyWith(nestingDepth: value);
  void updatePayloadSize(int value) =>
      state = state.copyWith(payloadSize: value);
  void updateWsMessageSize(int value) =>
      state = state.copyWith(wsMessageSize: value);
  void updateLoopDelayMs(int value) =>
      state = state.copyWith(loopDelayMs: value);
  void updateHttpMethod(String value) =>
      state = state.copyWith(httpMethod: value);
  void updatePreset(String value) => state = state.copyWith(preset: value);
  void updateUseAuthHeader(bool value) =>
      state = state.copyWith(useAuthHeader: value);
  void updateRandomize(bool value) => state = state.copyWith(randomize: value);
  void updateEnableHttp(bool value) =>
      state = state.copyWith(enableHttp: value);
  void updateHttpSendSuccess(bool value) =>
      state = state.copyWith(httpSendSuccess: value);
  void updateHttpSendErrors(bool value) =>
      state = state.copyWith(httpSendErrors: value);
  void updateEnableWs(bool value) => state = state.copyWith(enableWs: value);
  void updateEnableFileUploads(bool value) =>
      state = state.copyWith(enableFileUploads: value);
  void updateEnableLogging(bool value) =>
      state = state.copyWith(enableLogging: value);
  void updateEnableAnalytics(bool value) =>
      state = state.copyWith(enableAnalytics: value);
  void updateEnableRoutes(bool value) =>
      state = state.copyWith(enableRoutes: value);
  void updateEnableBlocEvents(bool value) =>
      state = state.copyWith(enableBlocEvents: value);
  void updateEnableRiverpod(bool value) =>
      state = state.copyWith(enableRiverpod: value);
  void updateEnableExceptions(bool value) =>
      state = state.copyWith(enableExceptions: value);
  void updateStreamMode(bool value) =>
      state = state.copyWith(streamMode: value);
  void updateStreamIntervalMs(int value) =>
      state = state.copyWith(streamIntervalMs: value);
}

final demoSettingsProvider =
    StateNotifierProvider<DemoSettingsNotifier, DemoSettings>(
  (ref) => DemoSettingsNotifier(),
);
