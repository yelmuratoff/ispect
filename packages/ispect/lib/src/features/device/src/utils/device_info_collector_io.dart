import 'dart:io';

Future<Map<String, dynamic>> collectPlatformDeviceInfo() async {
  final now = DateTime.now();

  return <String, dynamic>{
    'operatingSystem': Platform.operatingSystem,
    'osVersion': Platform.operatingSystemVersion,
    'localeName': Platform.localeName,
    'numberOfProcessors': Platform.numberOfProcessors,
    'timezone': '${now.timeZoneName} (${now.timeZoneOffset.inHours}h)',
    'dartVersion': Platform.version,
    'executable': Platform.executable,
    'executableArguments': Platform.executableArguments,
    'resolvedExecutable': Platform.resolvedExecutable,
  };
}
