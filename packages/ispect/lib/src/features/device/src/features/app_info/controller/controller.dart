part of '../app_info_screen.dart';

class AppInfoController extends ChangeNotifier {
  Map<String, dynamic>? _packageInfo;
  Map<String, dynamic>? _deviceInfo;

  Map<String, dynamic>? get packageInfo => _packageInfo;
  Map<String, dynamic>? get deviceInfo => _deviceInfo;

  Future<void> loadAll({
    required BuildContext context,
    required ISpectOptions options,
  }) async {
    try {
      _packageInfo = await _resolvePackageInfo(options);
      _deviceInfo = await _resolveDeviceInfo(options);
    } on Exception catch (error, stackTrace) {
      ISpect.logger.handle(exception: error, stackTrace: stackTrace);
      if (context.mounted) {
        await ISpectToaster.showErrorToast(
          context,
          title: error.toString(),
        );
      }
    }

    notifyListeners();
  }

  Future<Map<String, dynamic>> _resolvePackageInfo(
    ISpectOptions options,
  ) async {
    final provider = options.packageInfoProvider;
    if (provider != null) {
      final data = await provider();
      if (data.isNotEmpty) return data;
    }

    const buildMode = kReleaseMode
        ? 'release'
        : kProfileMode
            ? 'profile'
            : 'debug';

    return <String, dynamic>{
      'message':
          'Configure ISpectOptions.packageInfoProvider for detailed metadata.',
      'buildMode': buildMode,
      'platform': defaultTargetPlatform.name,
    };
  }

  Future<Map<String, dynamic>> _resolveDeviceInfo(
    ISpectOptions options,
  ) async {
    final provider = options.deviceInfoProvider;
    if (provider != null) {
      final data = await provider();
      if (data.isNotEmpty) return data;
    }

    return collectDeviceInfo();
  }

  Future<String> allData() async {
    final data = <String, dynamic>{
      'package_info': _packageInfo,
      'device_info': _deviceInfo,
    };
    return JsonTruncatorService.pretty(data);
  }
}
