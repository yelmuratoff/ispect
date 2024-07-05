part of '../app.dart';

class AppInfoController extends ChangeNotifier {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  AndroidDeviceInfo? _androidDeviceInfo;
  IosDeviceInfo? _iosDeviceInfo;
  PackageInfo? _packageInfo;

  PackageInfo? get packageInfo => _packageInfo;
  IosDeviceInfo? get iosDeviceInfo => _iosDeviceInfo;
  AndroidDeviceInfo? get androidDeviceInfo => _androidDeviceInfo;

  Future<void> loadAll({
    required BuildContext context,
    required Talker talker,
  }) async {
    try {
      await _loadPackageInfo(
        context: context,
        talker: talker,
      );
      if (Platform.isIOS) {
        _iosDeviceInfo = await _deviceInfo.iosInfo;
      } else if (Platform.isAndroid) {
        _androidDeviceInfo = await _deviceInfo.androidInfo;
      }
    } on Exception catch (e, st) {
      talker.handle(e, st);
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
    required Talker talker,
  }) async {
    try {
      _packageInfo = await PackageInfo.fromPlatform();
      notifyListeners();
    } on Exception catch (e, st) {
      talker.handle(e, st);
      if (context.mounted) {
        await ISpectToaster.showErrorToast(
          context,
          title: e.toString(),
        );
      }
    }
  }

  Future<String> allData() async {
    final buffer = StringBuffer()
      ..writeln('App Info')
      ..writeln('App Name: ${packageInfo!.appName}')
      ..writeln('Package Name: ${packageInfo!.packageName}')
      ..writeln('Version: ${packageInfo!.version}')
      ..writeln('Build Number: ${packageInfo!.buildNumber}')
      ..writeln('Device Info');
    if (Platform.isIOS) {
      buffer
        ..writeln('Name: ${iosDeviceInfo!.name}')
        ..writeln('System Name: ${iosDeviceInfo!.systemName}')
        ..writeln('System Version: ${iosDeviceInfo!.systemVersion}')
        ..writeln('Model: ${iosDeviceInfo!.model}')
        ..writeln('Localized Model: ${iosDeviceInfo!.localizedModel}')
        ..writeln(
          'Identifier For Vendor: ${iosDeviceInfo!.identifierForVendor}',
        );
    } else if (Platform.isAndroid) {
      buffer
        ..writeln('Version: ${androidDeviceInfo!.version}')
        ..writeln('Board: ${androidDeviceInfo!.board}')
        ..writeln('Bootloader: ${androidDeviceInfo!.bootloader}')
        ..writeln('Brand: ${androidDeviceInfo!.brand}')
        ..writeln('Device: ${androidDeviceInfo!.device}')
        ..writeln('Display: ${androidDeviceInfo!.display}')
        ..writeln('Fingerprint: ${androidDeviceInfo!.fingerprint}')
        ..writeln('Hardware: ${androidDeviceInfo!.hardware}')
        ..writeln('Host: ${androidDeviceInfo!.host}')
        ..writeln('Id: ${androidDeviceInfo!.id}')
        ..writeln('Manufacturer: ${androidDeviceInfo!.manufacturer}')
        ..writeln('Model: ${androidDeviceInfo!.model}')
        ..writeln('Product: ${androidDeviceInfo!.product}')
        ..writeln('Tags: ${androidDeviceInfo!.tags}')
        ..writeln('Type: ${androidDeviceInfo!.type}')
        ..writeln('Android ID: ${androidDeviceInfo!.id}');
    }
    return buffer.toString();
  }
}
