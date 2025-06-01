part of '../app_info_screen.dart';

class AppInfoController extends ChangeNotifier {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  PackageInfo? _packageInfo;
  BaseDeviceInfo? _baseDeviceInfo;

  PackageInfo? get packageInfo => _packageInfo;
  BaseDeviceInfo? get deviceInfo => _baseDeviceInfo;

  Future<void> loadAll({
    required BuildContext context,
  }) async {
    try {
      await _loadPackageInfo(
        context: context,
      );
      _baseDeviceInfo = await _deviceInfo.deviceInfo;
    } on Exception catch (e, st) {
      ISpect.logger.handle(exception: e, stackTrace: st);
      if (context.mounted) {
        await ISpectToaster.showErrorToast(
          context,
          title: e.toString(),
        );
      }
    }
    notifyListeners();
  }

  Future<void> _loadPackageInfo({
    required BuildContext context,
  }) async {
    try {
      _packageInfo = await PackageInfo.fromPlatform();
      notifyListeners();
    } on Exception catch (e, st) {
      ISpect.logger.handle(exception: e, stackTrace: st);
      if (context.mounted) {
        await ISpectToaster.showErrorToast(
          context,
          title: e.toString(),
        );
      }
    }
  }

  Future<String> allData() async {
    final data = <String, dynamic>{
      'package_info': _packageInfo?.data,
      'device_info': _baseDeviceInfo?.data,
    };
    final prettyData = JsonTruncatorService.pretty(data);
    return prettyData;
  }
}
