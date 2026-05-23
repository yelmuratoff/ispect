part of 'ispect_constants.dart';

const Map<String, Color> _kLightTypeColors = {
  /// Base logs section
  'error': Color.fromARGB(255, 192, 38, 38),
  'critical': Color.fromARGB(255, 142, 22, 22),
  'info': Color.fromARGB(255, 25, 118, 210),
  'debug': Color.fromARGB(255, 97, 97, 97),
  'verbose': Color.fromARGB(255, 117, 117, 117),
  'warning': Color.fromARGB(255, 255, 160, 0),
  'exception': Color.fromARGB(255, 211, 47, 47),
  'good': Color.fromARGB(255, 56, 142, 60),
  'print': Color.fromARGB(255, 25, 118, 210),
  'provider': Color.fromARGB(255, 25, 118, 210),
  'analytics': Color.fromARGB(255, 182, 177, 25),

  /// Http section
  'http-error': Color.fromARGB(255, 192, 38, 38),
  'http-request': Color(0xFF9C27B0),
  'http-response': Color(0xFF00C853),

  /// Bloc section
  'bloc-event': Color.fromARGB(255, 25, 118, 210),
  'bloc-transition': Color.fromARGB(255, 85, 139, 47),
  'bloc-close': Color.fromARGB(255, 192, 38, 38),
  'bloc-create': Color.fromARGB(255, 56, 142, 60),
  'bloc-state': Color.fromARGB(255, 0, 105, 135),
  'bloc-done': Color.fromARGB(255, 56, 142, 60),
  'bloc-error': Color.fromARGB(255, 192, 38, 38),

  'riverpod-add': Color.fromARGB(255, 56, 142, 60),
  'riverpod-update': Color.fromARGB(255, 0, 105, 135),
  'riverpod-dispose': Color(0xFFD50000),
  'riverpod-fail': Color.fromARGB(255, 192, 38, 38),

  /// Flutter section
  'route': Color(0xFF8E24AA),

  /// WebSocket
  'ws-sent': Color.fromARGB(255, 162, 0, 190),
  'ws-received': Color.fromARGB(255, 0, 158, 66),
  'ws-error': Color.fromARGB(255, 192, 38, 38),

  /// Database
  'db-query': Color.fromARGB(255, 25, 118, 210),
  'db-result': Color.fromARGB(255, 56, 142, 60),
  'db-error': Color.fromARGB(255, 192, 38, 38),

  /// Auth
  'auth-success': Color.fromARGB(255, 56, 142, 60),
  'auth-error': Color.fromARGB(255, 192, 38, 38),

  /// Storage
  'storage-result': Color.fromARGB(255, 56, 142, 60),
  'storage-query': Color.fromARGB(255, 25, 118, 210),
  'storage-error': Color.fromARGB(255, 192, 38, 38),

  /// Push
  'push-received': Color.fromARGB(255, 245, 124, 0),
  'push-sent': Color(0xFF9C27B0),
  'push-error': Color.fromARGB(255, 192, 38, 38),

  /// Payment
  'payment-success': Color.fromARGB(255, 56, 142, 60),
  'payment-error': Color.fromARGB(255, 192, 38, 38),

  /// State
  'state-change': Color.fromARGB(255, 85, 139, 47),
  'state-error': Color.fromARGB(255, 192, 38, 38),

  /// SSE
  'sse-received': Color.fromARGB(255, 0, 158, 66),
  'sse-error': Color.fromARGB(255, 192, 38, 38),

  /// gRPC
  'grpc-request': Color(0xFF9C27B0),
  'grpc-response': Color(0xFF00C853),
  'grpc-error': Color.fromARGB(255, 192, 38, 38),

  /// GraphQL
  'graphql-request': Color.fromARGB(255, 106, 27, 154),
  'graphql-response': Color(0xFF00C853),
  'graphql-error': Color.fromARGB(255, 192, 38, 38),

  /// Performance
  'performance-jank': Color.fromARGB(255, 255, 160, 0),
  'performance-error': Color.fromARGB(255, 192, 38, 38),
};

const Map<String, Color> _kDarkTypeColors = {
  /// Base logs section
  'error': Color.fromARGB(255, 239, 83, 80),
  'critical': Color.fromARGB(255, 198, 40, 40),
  'info': Color.fromARGB(255, 66, 165, 245),
  'debug': Color.fromARGB(255, 158, 158, 158),
  'verbose': Color.fromARGB(255, 189, 189, 189),
  'warning': Color.fromARGB(255, 239, 108, 0),
  'exception': Color.fromARGB(255, 239, 83, 80),
  'good': Color.fromARGB(255, 120, 230, 129),
  'print': Color.fromARGB(255, 66, 165, 245),
  'provider': Color.fromARGB(255, 66, 165, 245),
  'analytics': Color.fromARGB(255, 255, 255, 0),

  /// Http section
  'http-error': Color.fromARGB(255, 239, 83, 80),
  'http-request': Color(0xFFF602C1),
  'http-response': Color(0xFF26FF3C),

  /// Bloc section
  'bloc-event': Color(0xFF63FAFE),
  'bloc-transition': Color(0xFF56FEA8),
  'bloc-close': Color(0xFFFF005F),
  'bloc-create': Color.fromARGB(255, 120, 230, 129),
  'bloc-state': Color.fromARGB(255, 0, 125, 160),
  'bloc-done': Color.fromARGB(255, 120, 230, 129),
  'bloc-error': Color.fromARGB(255, 239, 83, 80),

  'riverpod-add': Color.fromARGB(255, 120, 230, 129),
  'riverpod-update': Color.fromARGB(255, 120, 180, 190),
  'riverpod-dispose': Color(0xFFFF005F),
  'riverpod-fail': Color.fromARGB(255, 239, 83, 80),

  /// Flutter section
  'route': Color(0xFFAF5FFF),

  /// WebSocket
  'ws-sent': Color(0xFFF602C1),
  'ws-received': Color(0xFF26FF3C),
  'ws-error': Color.fromARGB(255, 239, 83, 80),

  /// Database
  'db-query': Color.fromARGB(255, 66, 165, 245),
  'db-result': Color.fromARGB(255, 120, 230, 129),
  'db-error': Color.fromARGB(255, 239, 83, 80),

  /// Auth
  'auth-success': Color.fromARGB(255, 120, 230, 129),
  'auth-error': Color.fromARGB(255, 239, 83, 80),

  /// Storage
  'storage-result': Color.fromARGB(255, 120, 230, 129),
  'storage-query': Color.fromARGB(255, 66, 165, 245),
  'storage-error': Color.fromARGB(255, 239, 83, 80),

  /// Push
  'push-received': Color.fromARGB(255, 255, 167, 38),
  'push-sent': Color(0xFFF602C1),
  'push-error': Color.fromARGB(255, 239, 83, 80),

  /// Payment
  'payment-success': Color.fromARGB(255, 120, 230, 129),
  'payment-error': Color.fromARGB(255, 239, 83, 80),

  /// State
  'state-change': Color(0xFF56FEA8),
  'state-error': Color.fromARGB(255, 239, 83, 80),

  /// SSE
  'sse-received': Color(0xFF26FF3C),
  'sse-error': Color.fromARGB(255, 239, 83, 80),

  /// gRPC
  'grpc-request': Color(0xFFF602C1),
  'grpc-response': Color(0xFF26FF3C),
  'grpc-error': Color.fromARGB(255, 239, 83, 80),

  /// GraphQL
  'graphql-request': Color.fromARGB(255, 186, 104, 255),
  'graphql-response': Color(0xFF26FF3C),
  'graphql-error': Color.fromARGB(255, 239, 83, 80),

  /// Performance
  'performance-jank': Color.fromARGB(255, 255, 167, 38),
  'performance-error': Color.fromARGB(255, 239, 83, 80),
};
