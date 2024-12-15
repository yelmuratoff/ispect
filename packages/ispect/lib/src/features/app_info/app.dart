import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/utils/copy_clipboard.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:talker_flutter/talker_flutter.dart';

part 'controller/controller.dart';
part 'view/app_info_view.dart';
part 'widgets/device_info_body.dart';
part 'widgets/package_info_body.dart';
part 'widgets/key_value_line.dart';

class AppInfoPage extends StatefulWidget {
  const AppInfoPage({required this.talker, super.key});
  final Talker talker;

  @override
  State<AppInfoPage> createState() => _AppInfoPageState();
}

class _AppInfoPageState extends State<AppInfoPage> {
  final _contorller = AppInfoController();

  @override
  void initState() {
    super.initState();
    _contorller.loadAll(context: context, talker: widget.talker);
  }

  @override
  void dispose() {
    _contorller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _AppInfoView(
        controller: _contorller,
      );
}
