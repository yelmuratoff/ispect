import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/utils/adjust_color.dart';
import 'package:ispect/src/common/utils/copy_clipboard.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';
import 'package:ispect/src/features/device/src/utils/device_info_collector.dart';
import 'package:ispect/src/features/inspector/src/widgets/color_picker/utils.dart';

part 'controller/controller.dart';
part 'widgets/device_info_body.dart';
part 'widgets/key_value_line.dart';
part 'widgets/package_info_body.dart';

class AppInfoScreen extends StatefulWidget {
  const AppInfoScreen({super.key});

  void push(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => this,
        settings: const RouteSettings(name: 'ISpect App Info Screen'),
      ),
    );
  }

  @override
  State<AppInfoScreen> createState() => _AppInfoScreenState();
}

class _AppInfoScreenState extends State<AppInfoScreen> {
  final _controller = AppInfoController();

  bool _didRequestLoad = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didRequestLoad) return;
    _didRequestLoad = true;

    final options = ISpect.read(context).options;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _controller.loadAll(
        context: context,
        options: options,
      );
    });
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
              data: _controller.deviceInfo,
            ),
            const Gap(10),
            PackageInfoBody(
              data: _controller.packageInfo,
            ),
          ],
        ),
      ),
    );
  }
}
