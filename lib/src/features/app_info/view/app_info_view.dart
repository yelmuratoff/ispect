part of '../app.dart';

class _AppInfoView extends StatelessWidget {
  final AppInfoController controller;
  const _AppInfoView({required this.controller});

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
                    title: context.ispectL10n.copied_to_clipboard,
                  );
                }
              },
            ),
          ],
        ),
        body: AnimatedBuilder(
          animation: controller,
          builder: (context, _) => ListView(
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
