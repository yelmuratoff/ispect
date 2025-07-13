// Cross-platform logs file utilities
export 'base/base.dart';
export 'factory/factory.dart';

// Export platform-specific implementations
export 'implementations/native_logs_file.dart'
    if (dart.library.js_interop) 'implementations/web_logs_file.dart';
export 'implementations/web_logs_file.dart'
    if (dart.library.io) 'implementations/native_logs_file.dart';
