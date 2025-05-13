import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect_device/src/features/app_info/utils/copy.dart';
import 'package:package_info_plus/package_info_plus.dart';

part 'controller/controller.dart';
part 'view/app_info_view.dart';
part 'widgets/device_info_body.dart';
part 'widgets/key_value_line.dart';
part 'widgets/package_info_body.dart';

class AppInfoScreen extends StatefulWidget {
  const AppInfoScreen({required this.iSpectify, super.key});
  final ISpectify iSpectify;

  @override
  State<AppInfoScreen> createState() => _AppInfoScreenState();
}

class _AppInfoScreenState extends State<AppInfoScreen> {
  final _contorller = AppInfoController();

  @override
  void initState() {
    super.initState();
    _contorller.loadAll(
      context: context,
      );
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
