part of '../app.dart';

class DeviceInfoBody extends StatelessWidget {
  const DeviceInfoBody({
    super.key,
    this.androidDeviceInfo,
    this.iosDeviceInfo,
  });

  final AndroidDeviceInfo? androidDeviceInfo;
  final IosDeviceInfo? iosDeviceInfo;

  @override
  Widget build(BuildContext context) {
    Widget? child;

    if (androidDeviceInfo != null) {
      child = _AndroidInfoBody(
        androidDeviceInfo: androidDeviceInfo!,
      );
    } else if (iosDeviceInfo != null) {
      child = _IosInfoBody(
        iosDeviceInfo: iosDeviceInfo!,
      );
    } else {
      child = const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Device info',
            style: context.ispectTheme.textTheme.bodyMedium?.copyWith(
              color: context.ispectTheme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: child,
        ),
      ],
    );
  }
}

class _AndroidInfoBody extends StatelessWidget {
  const _AndroidInfoBody({
    required AndroidDeviceInfo androidDeviceInfo,
  }) : _deviceInfo = androidDeviceInfo;

  final AndroidDeviceInfo _deviceInfo;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return SizedBox(
      width: size.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KeyValueLine(
            k: 'Device:',
            v: _deviceInfo.device,
          ),
          KeyValueLine(
            k: 'Model:',
            v: _deviceInfo.model,
          ),
          KeyValueLine(
            k: 'Product:',
            v: _deviceInfo.product,
          ),
          KeyValueLine(
            k: 'Version:',
            v: _deviceInfo.version.release,
          ),
          KeyValueLine(
            k: 'Version codename:',
            v: _deviceInfo.version.codename,
          ),
          KeyValueLine(
            k: 'Version incremental:',
            v: _deviceInfo.version.incremental,
          ),
          KeyValueLine(
            k: 'Version securityPatch:',
            v: _deviceInfo.version.securityPatch ?? '',
          ),
          KeyValueLine(
            k: 'Version previewSdkInt:',
            v: '${_deviceInfo.version.previewSdkInt}',
          ),
          KeyValueLine(
            k: 'Version baseOS:',
            v: _deviceInfo.version.baseOS ?? '',
          ),
          KeyValueLine(
            k: 'Device foundation:',
            v: (_deviceInfo.isPhysicalDevice) ? 'Physical' : 'Emulator',
          ),
        ]
            .map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: e,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _IosInfoBody extends StatelessWidget {
  const _IosInfoBody({
    required IosDeviceInfo iosDeviceInfo,
  }) : _deviceInfo = iosDeviceInfo;

  final IosDeviceInfo _deviceInfo;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return SizedBox(
      width: size.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KeyValueLine(
            k: 'Model:',
            v: _deviceInfo.model,
          ),
          KeyValueLine(
            k: 'Name:',
            v: _deviceInfo.name,
          ),
          KeyValueLine(
            k: 'System name:',
            v: _deviceInfo.systemName,
          ),
          KeyValueLine(
            k: 'System version:',
            v: _deviceInfo.systemVersion,
          ),
          KeyValueLine(
            k: 'Identifier for vendor:',
            v: _deviceInfo.identifierForVendor ?? '',
          ),
          KeyValueLine(
            k: 'Localized model:',
            v: _deviceInfo.localizedModel,
          ),
          KeyValueLine(
            k: 'Device foundation:',
            v: _deviceInfo.isPhysicalDevice ? 'Physical' : 'Emulator',
          ),
        ]
            .map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: e,
              ),
            )
            .toList(),
      ),
    );
  }
}
