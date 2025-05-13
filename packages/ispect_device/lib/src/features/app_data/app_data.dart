import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect_device/src/core/localization/generated/ispect_localizations.dart';
import 'package:ispect_device/src/features/app_info/utils/copy.dart';
import 'package:ispect_device/src/services/cache/cache_manager.dart';
import 'package:ispect_device/src/services/file/src/file_service.dart';

part 'view/view.dart';
part 'controller/controller.dart';

class AppDataScreen extends StatefulWidget {
  const AppDataScreen({required this.iSpectify, super.key});
  final ISpectify iSpectify;

  @override
  State<AppDataScreen> createState() => _AppDataScreenState();
}

class _AppDataScreenState extends State<AppDataScreen> with CacheMixin {
  final _controller = AppDataController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.loadFilesList(context: context);
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
            index: value,
          );
        },
        deleteFiles: () {
          _controller.deleteFiles(
            context: context,
          );
        },
        cacheSizeNotifier: cacheSizeNotifier,
        clearCache: () async {
          await appCacheManager.deleteCacheDir(
            isAndroid: Theme.of(context).platform == TargetPlatform.android,
          );
          await updateCacheSize();
          if (context.mounted) {
            await _controller.loadFilesList(
              context: context,
            );
          }
          if (context.mounted) {
            await ISpectToaster.showSuccessToast(
              context,
              title: 'Cache cleared',
            );
          }
        },
      );
}

mixin CacheMixin on State<AppDataScreen> {
  late final AppCacheManager appCacheManager;

  late ValueNotifier<String> cacheSizeNotifier = ValueNotifier<String>('');

  @override
  void initState() {
    super.initState();
    appCacheManager = AppCacheManager();
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
