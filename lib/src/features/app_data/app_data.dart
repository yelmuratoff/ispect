import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/services/file/file_service.dart';
import 'package:ispect/src/common/widgets/dialogs/toaster.dart';
import 'package:talker_flutter/talker_flutter.dart';

part 'view/view.dart';
part 'controller/controller.dart';

class AppDataPage extends StatefulWidget {
  final Talker talker;
  const AppDataPage({super.key, required this.talker});

  @override
  State<AppDataPage> createState() => _AppDataPageState();
}

class _AppDataPageState extends State<AppDataPage> {
  final _controller = AppDataController();

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.loadFilesList(
        context: context,
        talker: widget.talker,
      );
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) => _AppDataView(
        controller: _controller,
        deleteFile: (value) {
          _controller.deleteFile(
            context: context,
            talker: widget.talker,
            index: value,
          );
        },
        deleteFiles: () {
          _controller.deleteFiles(
            context: context,
            talker: widget.talker,
          );
        },
      );
}
