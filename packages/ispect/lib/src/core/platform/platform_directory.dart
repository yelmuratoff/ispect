import 'package:ispect/src/core/platform/platform_directory_native.dart'
    if (dart.library.js_interop) 'platform_directory_web.dart' as impl;

export 'platform_directory_base.dart' show PlatformDirectoryProvider;

/// Accessor to the platform-specific directory provider implementation.
const platformDirectoryProvider = impl.platformDirectoryProvider;
