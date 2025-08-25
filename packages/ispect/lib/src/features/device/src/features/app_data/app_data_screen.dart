import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/utils/copy_clipboard.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';
import 'package:ispect/src/features/device/src/core/localization/generated/ispect_localizations.dart';
import 'package:ispect/src/features/device/src/services/cache/cache_manager.dart';
import 'package:ispect/src/features/device/src/services/file/file_service.dart';
import 'package:open_filex/open_filex.dart';

part 'view/view.dart';
part 'controller/controller.dart';

class AppDataScreen extends StatefulWidget {
  const AppDataScreen({super.key});

  void push(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => this,
        settings: const RouteSettings(name: 'ISpect App Data Screen'),
      ),
    );
  }

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
          await appCacheManager.deleteCacheDir();
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
  late final BaseCacheService appCacheManager;

  late ValueNotifier<String> cacheSizeNotifier = ValueNotifier<String>('');

  @override
  void initState() {
    super.initState();
    appCacheManager = const AppCacheManager();
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
