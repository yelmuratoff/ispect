import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/services/cache/src/app_cache_manager.dart';
import 'package:ispect/src/common/services/file/file_service.dart';
import 'package:ispect/src/common/widgets/dialogs/toaster.dart';
// import 'package:simple_app_cache_manager/simple_app_cache_manager.dart';
import 'package:talker_flutter/talker_flutter.dart';

part 'view/view.dart';
part 'controller/controller.dart';

class AppDataPage extends StatefulWidget {
  const AppDataPage({required this.talker, super.key});
  final Talker talker;

  @override
  State<AppDataPage> createState() => _AppDataPageState();
}

class _AppDataPageState extends State<AppDataPage> with CacheMixin {
  final _controller = AppDataController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.loadFilesList(context: context, talker: widget.talker);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
        cacheSizeNotifier: cacheSizeNotifier,
        clearCache: () async {
          await appCacheManager.deleteCacheDir(
            isAndroid: context.ispectTheme.platform == TargetPlatform.android,
          );
          await updateCacheSize();
          if (context.mounted) {
            await _controller.loadFilesList(
              context: context,
              talker: widget.talker,
            );
          }
          if (context.mounted) {
            await ISpectToaster.showSuccessToast(
              context,
              title: context.ispectL10n.cacheCleared,
            );
          }
        },
      );
}

mixin CacheMixin on State<AppDataPage> {
  late final AppCacheManager appCacheManager;
  // late final SimpleAppCacheManager cacheManager;

  late ValueNotifier<String> cacheSizeNotifier = ValueNotifier<String>('');

  @override
  void initState() {
    super.initState();
    appCacheManager = AppCacheManager();
    // cacheManager = SimpleAppCacheManager();
    updateCacheSize();
  }

  Future<void> updateCacheSize() async {
    final cacheSize = await appCacheManager.getCacheSize();
    cacheSizeNotifier.value = appCacheManager.formatSize(cacheSize);
  }

  @override
  void dispose() {
    cacheSizeNotifier.dispose();
    super.dispose();
  }
}
