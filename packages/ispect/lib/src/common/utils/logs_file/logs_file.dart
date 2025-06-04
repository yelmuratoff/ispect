// Cross-platform logs file utilities
export 'base_logs_file.dart';
export 'logs_file_factory.dart';

// Export platform-specific implementations
export 'native_logs_file.dart' if (dart.library.html) 'web_logs_file.dart';
export 'web_logs_file.dart' if (dart.library.io) 'native_logs_file.dart';
