part of '../app_data.dart';

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
      ),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ValueListenableBuilder(
                    valueListenable: cacheSizeNotifier,
                    builder: (context, cacheSize, _) => Text(
                      context.ispectL10n.cacheSize(cacheSize),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.ispectTheme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (cacheSizeNotifier.value != '0.00 B' &&
                      controller.files.isNotEmpty)
                    ElevatedButton(
                      onPressed: clearCache,
                      child: Text(context.ispectL10n.clearCache),
                    ),
                ],
              ),
            ),
            const Gap(10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.ispectL10n.appData,
                    style: context.ispectTheme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  Text(
                    context.ispectL10n.totalFilesCount(controller.files.length),
                    style: context.ispectTheme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(top: 10),
                itemCount: controller.files.length,
                separatorBuilder: (_, __) => const SizedBox(height: 0),
                itemBuilder: (_, i) {
                  final f = controller.files[i];
                  return Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '$i. File:\n ${f.path}',
                            style: context.ispectTheme.textTheme.labelMedium,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
