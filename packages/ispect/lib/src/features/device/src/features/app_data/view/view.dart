part of '../app_data_screen.dart';

class _AppDataView extends StatelessWidget {
  const _AppDataView({
    required this.controller,
    required this.deleteFiles,
    required this.deleteFile,
    required this.cacheSizeNotifier,
    required this.clearCache,
  });

  final AppDataController controller;
  final VoidCallback deleteFiles;
  final void Function(int index) deleteFile;
  final ValueNotifier<String> cacheSizeNotifier;
  final VoidCallback clearCache;

  static const _horizontalPadding = EdgeInsets.symmetric(horizontal: 16);
  static const _verticalGap = Gap(10);
  static const _zeroMB = '0.00 MB';

  @override
  Widget build(BuildContext context) {
    final iSpect = ISpect.read(context);
    final backgroundColor = iSpect.theme.backgroundColor(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCacheHeader(context),
            _verticalGap,
            _buildAppDataHeader(context),
            Expanded(
              child: _buildFilesList(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCacheHeader(BuildContext context) => Padding(
        padding: _horizontalPadding,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ValueListenableBuilder<String>(
              valueListenable: cacheSizeNotifier,
              builder: (context, cacheSize, _) => Text(
                ISpectDeviceLocalization.of(context)?.cacheSize(cacheSize) ??
                    'Cache size: $cacheSize',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
              ),
            ),
            const Gap(20),
            ValueListenableBuilder<String>(
              valueListenable: cacheSizeNotifier,
              builder: (context, cacheSize, _) {
                if (cacheSize == _zeroMB) return const SizedBox.shrink();

                return ElevatedButton(
                  onPressed: clearCache,
                  child: Text(
                    ISpectDeviceLocalization.of(context)?.clearCache ??
                        'Clear cache',
                  ),
                );
              },
            ),
          ],
        ),
      );

  Widget _buildAppDataHeader(BuildContext context) {
    final localization = ISpectDeviceLocalization.of(context);
    final filesCount = controller.files.length;

    return Padding(
      padding: _horizontalPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localization?.appData ?? 'App data',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
          ),
          Text(
            localization?.totalFilesCount(filesCount) ??
                'Total files count: $filesCount',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildFilesList(BuildContext context) => ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(top: 10),
        itemCount: controller.files.length,
        itemBuilder: (_, index) => _FileListItem(
          index: index,
          file: controller.files[index],
          onDelete: () => deleteFile(index),
        ),
      );
}

class _FileListItem extends StatelessWidget {
  const _FileListItem({
    required this.index,
    required this.file,
    required this.onDelete,
  });

  final int index;
  final File file;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(10),
        child: InkWell(
          onLongPress: () => copyClipboard(context, value: file.path),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '$index. File:\n ${file.path}',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                onPressed: () {
                  OpenFilex.open(file.path);
                },
                icon: const Icon(Icons.open_in_new_rounded),
              ),
              const Gap(8),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                onPressed: onDelete,
                icon: const Icon(Icons.delete_rounded),
              ),
            ],
          ),
        ),
      );
}
