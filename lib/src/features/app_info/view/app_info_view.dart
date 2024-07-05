part of '../app.dart';

class _AppInfoView extends StatelessWidget {
  const _AppInfoView({required this.controller});
  final AppInfoController controller;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.copy_all_rounded),
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(
                    text: await controller.allData(),
                  ),
                );
                if (context.mounted) {
                  await ISpectToaster.showInfoToast(
                    context,
                    title: context.ispectL10n.copiedToClipboard,
                  );
                }
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
