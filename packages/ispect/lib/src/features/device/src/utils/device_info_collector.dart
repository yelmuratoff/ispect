import 'package:flutter/foundation.dart';

import 'package:ispect/src/features/device/src/utils/device_info_collector_io.dart'
    if (dart.library.html)
      'package:ispect/src/features/device/src/utils/device_info_collector_web.dart';

/// Collects lightweight device information without relying on external
/// platform plugins.
Future<Map<String, dynamic>> collectDeviceInfo() async {
  try {
    return await collectPlatformDeviceInfo();
  } catch (error) {
    if (kDebugMode) {
      debugPrint('ISpect device info collection failed: $error');
    }
    return const <String, dynamic>{
      'message': 'Device info unavailable. Provide ISpectOptions.deviceInfoProvider for custom data.',
    };
  }
}
