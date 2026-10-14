part of 'ispect_constants.dart';

final Map<String, Color> _kLightTypeColors = Map.unmodifiable({
  /// Base logs section
  ISpectLogType.error.key: const Color.fromARGB(255, 192, 38, 38),
  ISpectLogType.critical.key: const Color.fromARGB(255, 142, 22, 22),
  ISpectLogType.info.key: const Color.fromARGB(255, 25, 118, 210),
  ISpectLogType.debug.key: const Color.fromARGB(255, 97, 97, 97),
  ISpectLogType.verbose.key: const Color.fromARGB(255, 117, 117, 117),
  ISpectLogType.warning.key: const Color.fromARGB(255, 255, 160, 0),
  ISpectLogType.exception.key: const Color.fromARGB(255, 211, 47, 47),
  ISpectLogType.good.key: const Color.fromARGB(255, 56, 142, 60),
  ISpectLogType.print.key: const Color.fromARGB(255, 25, 118, 210),
  ISpectLogType.provider.key: const Color.fromARGB(255, 25, 118, 210),
  ISpectLogType.analytics.key: const Color.fromARGB(255, 182, 177, 25),

  /// Http section
  ISpectLogType.httpError.key: const Color.fromARGB(255, 192, 38, 38),
  ISpectLogType.httpRequest.key: const Color(0xFF9C27B0),
  ISpectLogType.httpResponse.key: const Color(0xFF00C853),

  /// Bloc section
  ISpectLogType.blocEvent.key: const Color.fromARGB(255, 25, 118, 210),
  ISpectLogType.blocTransition.key: const Color.fromARGB(255, 85, 139, 47),
  ISpectLogType.blocClose.key: const Color.fromARGB(255, 192, 38, 38),
  ISpectLogType.blocCreate.key: const Color.fromARGB(255, 56, 142, 60),
  ISpectLogType.blocState.key: const Color.fromARGB(255, 0, 105, 135),
  ISpectLogType.blocDone.key: const Color.fromARGB(255, 56, 142, 60),
  ISpectLogType.blocError.key: const Color.fromARGB(255, 192, 38, 38),

  ISpectLogType.riverpodAdd.key: const Color.fromARGB(255, 56, 142, 60),
  ISpectLogType.riverpodUpdate.key: const Color.fromARGB(255, 0, 105, 135),
  ISpectLogType.riverpodDispose.key: const Color(0xFFD50000),
  ISpectLogType.riverpodFail.key: const Color.fromARGB(255, 192, 38, 38),

  /// Flutter section
  ISpectLogType.route.key: const Color(0xFF8E24AA),

  /// WebSocket
  ISpectLogType.wsSent.key: const Color.fromARGB(255, 162, 0, 190),
  ISpectLogType.wsReceived.key: const Color.fromARGB(255, 0, 158, 66),
  ISpectLogType.wsError.key: const Color.fromARGB(255, 192, 38, 38),
  ISpectLogType.wsState.key: const Color.fromARGB(255, 0, 131, 143),

  /// Database
  ISpectLogType.dbQuery.key: const Color.fromARGB(255, 25, 118, 210),
  ISpectLogType.dbResult.key: const Color.fromARGB(255, 56, 142, 60),
  ISpectLogType.dbError.key: const Color.fromARGB(255, 192, 38, 38),

  /// Auth
  ISpectLogType.authSuccess.key: const Color.fromARGB(255, 56, 142, 60),
  ISpectLogType.authError.key: const Color.fromARGB(255, 192, 38, 38),

  /// Storage
  ISpectLogType.storageResult.key: const Color.fromARGB(255, 56, 142, 60),
  ISpectLogType.storageQuery.key: const Color.fromARGB(255, 25, 118, 210),
  ISpectLogType.storageError.key: const Color.fromARGB(255, 192, 38, 38),

  /// Push
  ISpectLogType.pushReceived.key: const Color.fromARGB(255, 245, 124, 0),
  ISpectLogType.pushSent.key: const Color(0xFF9C27B0),
  ISpectLogType.pushError.key: const Color.fromARGB(255, 192, 38, 38),

  /// Payment
  ISpectLogType.paymentSuccess.key: const Color.fromARGB(255, 56, 142, 60),
  ISpectLogType.paymentError.key: const Color.fromARGB(255, 192, 38, 38),

  /// State
  ISpectLogType.stateChange.key: const Color.fromARGB(255, 85, 139, 47),
  ISpectLogType.stateError.key: const Color.fromARGB(255, 192, 38, 38),

  /// SSE
  ISpectLogType.sseReceived.key: const Color.fromARGB(255, 0, 158, 66),
  ISpectLogType.sseError.key: const Color.fromARGB(255, 192, 38, 38),

  /// gRPC
  ISpectLogType.grpcRequest.key: const Color(0xFF9C27B0),
  ISpectLogType.grpcResponse.key: const Color(0xFF00C853),
  ISpectLogType.grpcError.key: const Color.fromARGB(255, 192, 38, 38),

  /// GraphQL
  ISpectLogType.graphqlRequest.key: const Color.fromARGB(255, 106, 27, 154),
  ISpectLogType.graphqlResponse.key: const Color(0xFF00C853),
  ISpectLogType.graphqlError.key: const Color.fromARGB(255, 192, 38, 38),

  /// Performance
  ISpectLogType.performanceJank.key: const Color.fromARGB(255, 255, 160, 0),
  ISpectLogType.performanceError.key: const Color.fromARGB(255, 192, 38, 38),
});

final Map<String, Color> _kDarkTypeColors = Map.unmodifiable({
  /// Base logs section
  ISpectLogType.error.key: const Color.fromARGB(255, 239, 83, 80),
  ISpectLogType.critical.key: const Color.fromARGB(255, 198, 40, 40),
  ISpectLogType.info.key: const Color.fromARGB(255, 66, 165, 245),
  ISpectLogType.debug.key: const Color.fromARGB(255, 158, 158, 158),
  ISpectLogType.verbose.key: const Color.fromARGB(255, 189, 189, 189),
  ISpectLogType.warning.key: const Color.fromARGB(255, 239, 108, 0),
  ISpectLogType.exception.key: const Color.fromARGB(255, 239, 83, 80),
  ISpectLogType.good.key: const Color.fromARGB(255, 120, 230, 129),
  ISpectLogType.print.key: const Color.fromARGB(255, 66, 165, 245),
  ISpectLogType.provider.key: const Color.fromARGB(255, 66, 165, 245),
  ISpectLogType.analytics.key: const Color.fromARGB(255, 255, 255, 0),

  /// Http section
  ISpectLogType.httpError.key: const Color.fromARGB(255, 239, 83, 80),
  ISpectLogType.httpRequest.key: const Color(0xFFF602C1),
  ISpectLogType.httpResponse.key: const Color(0xFF26FF3C),

  /// Bloc section
  ISpectLogType.blocEvent.key: const Color(0xFF63FAFE),
  ISpectLogType.blocTransition.key: const Color(0xFF56FEA8),
  ISpectLogType.blocClose.key: const Color(0xFFFF005F),
  ISpectLogType.blocCreate.key: const Color.fromARGB(255, 120, 230, 129),
  ISpectLogType.blocState.key: const Color.fromARGB(255, 0, 125, 160),
  ISpectLogType.blocDone.key: const Color.fromARGB(255, 120, 230, 129),
  ISpectLogType.blocError.key: const Color.fromARGB(255, 239, 83, 80),

  ISpectLogType.riverpodAdd.key: const Color.fromARGB(255, 120, 230, 129),
  ISpectLogType.riverpodUpdate.key: const Color.fromARGB(255, 120, 180, 190),
  ISpectLogType.riverpodDispose.key: const Color(0xFFFF005F),
  ISpectLogType.riverpodFail.key: const Color.fromARGB(255, 239, 83, 80),

  /// Flutter section
  ISpectLogType.route.key: const Color(0xFFAF5FFF),

  /// WebSocket
  ISpectLogType.wsSent.key: const Color(0xFFF602C1),
  ISpectLogType.wsReceived.key: const Color(0xFF26FF3C),
  ISpectLogType.wsError.key: const Color.fromARGB(255, 239, 83, 80),
  ISpectLogType.wsState.key: const Color(0xFF4DD0E1),

  /// Database
  ISpectLogType.dbQuery.key: const Color.fromARGB(255, 66, 165, 245),
  ISpectLogType.dbResult.key: const Color.fromARGB(255, 120, 230, 129),
  ISpectLogType.dbError.key: const Color.fromARGB(255, 239, 83, 80),

  /// Auth
  ISpectLogType.authSuccess.key: const Color.fromARGB(255, 120, 230, 129),
  ISpectLogType.authError.key: const Color.fromARGB(255, 239, 83, 80),

  /// Storage
  ISpectLogType.storageResult.key: const Color.fromARGB(255, 120, 230, 129),
  ISpectLogType.storageQuery.key: const Color.fromARGB(255, 66, 165, 245),
  ISpectLogType.storageError.key: const Color.fromARGB(255, 239, 83, 80),

  /// Push
  ISpectLogType.pushReceived.key: const Color.fromARGB(255, 255, 167, 38),
  ISpectLogType.pushSent.key: const Color(0xFFF602C1),
  ISpectLogType.pushError.key: const Color.fromARGB(255, 239, 83, 80),

  /// Payment
  ISpectLogType.paymentSuccess.key: const Color.fromARGB(255, 120, 230, 129),
  ISpectLogType.paymentError.key: const Color.fromARGB(255, 239, 83, 80),

  /// State
  ISpectLogType.stateChange.key: const Color(0xFF56FEA8),
  ISpectLogType.stateError.key: const Color.fromARGB(255, 239, 83, 80),

  /// SSE
  ISpectLogType.sseReceived.key: const Color(0xFF26FF3C),
  ISpectLogType.sseError.key: const Color.fromARGB(255, 239, 83, 80),

  /// gRPC
  ISpectLogType.grpcRequest.key: const Color(0xFFF602C1),
  ISpectLogType.grpcResponse.key: const Color(0xFF26FF3C),
  ISpectLogType.grpcError.key: const Color.fromARGB(255, 239, 83, 80),

  /// GraphQL
  ISpectLogType.graphqlRequest.key: const Color.fromARGB(255, 186, 104, 255),
  ISpectLogType.graphqlResponse.key: const Color(0xFF26FF3C),
  ISpectLogType.graphqlError.key: const Color.fromARGB(255, 239, 83, 80),

  /// Performance
  ISpectLogType.performanceJank.key: const Color.fromARGB(255, 255, 167, 38),
  ISpectLogType.performanceError.key: const Color.fromARGB(255, 239, 83, 80),
});
