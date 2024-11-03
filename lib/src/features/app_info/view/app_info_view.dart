part of '../app.dart';

class _AppInfoView extends StatelessWidget {
  const _AppInfoView({required this.controller});
  final AppInfoController controller;

  @override
  Widget build(BuildContext context) {
    final iSpect = ISpect.read(context);
    return Scaffold(
      backgroundColor: iSpect.theme.backgroundColor(context),
      appBar: AppBar(
        backgroundColor: iSpect.theme.backgroundColor(context),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_all_rounded),
            onPressed: () async {
              copyClipboard(
                // ignore: use_build_context_synchronously
                context,
                value: await controller.allData(),
                showValue: false,
              );
            },
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: controller,
        builder: (_, __) => ListView(
          physics: const BouncingScrollPhysics(),
          children: [
            const SizedBox(height: 10),
            DeviceInfoBody(
              androidDeviceInfo: controller.androidDeviceInfo,
              iosDeviceInfo: controller.iosDeviceInfo,
            ),
            const SizedBox(height: 10),
            PackageInfoBody(
              packageInfo: controller.packageInfo,
            ),
          ],
        ),
      ),
    );
  }
}
