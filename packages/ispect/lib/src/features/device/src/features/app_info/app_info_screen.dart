import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/utils/adjust_color.dart';
import 'package:ispect/src/common/utils/copy_clipboard.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';
import 'package:ispect/src/features/inspector/src/widgets/color_picker/utils.dart';
import 'package:package_info_plus/package_info_plus.dart';

part 'controller/controller.dart';
part 'widgets/device_info_body.dart';
part 'widgets/key_value_line.dart';
part 'widgets/package_info_body.dart';

class AppInfoScreen extends StatefulWidget {
  const AppInfoScreen({super.key});

  @override
  State<AppInfoScreen> createState() => _AppInfoScreenState();
}

class _AppInfoScreenState extends State<AppInfoScreen> {
  final _controller = AppInfoController();

  @override
  void initState() {
    super.initState();
    _controller.loadAll(
      context: context,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
              final value = await _controller.allData();
              if (context.mounted) {
                copyClipboard(
                  context,
                  value: value,
                );
              }
            },
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) => ListView(
          physics: const BouncingScrollPhysics(),
          children: [
            const Gap(10),
            DeviceInfoBody(
              data: _controller.deviceInfo?.data,
            ),
            const Gap(10),
            PackageInfoBody(
              data: _controller.packageInfo?.data,
            ),
          ],
        ),
      ),
    );
  }
}
