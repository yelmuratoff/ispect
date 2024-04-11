part of '../app_data.dart';

class _AppDataView extends StatelessWidget {
  final AppDataController controller;
  final void Function() deleteFiles;
  final void Function(int) deleteFile;
  final ValueNotifier<String> cacheSizeNotifier;
  final void Function() clearCache;
  const _AppDataView({
    required this.controller,
    required this.deleteFiles,
    required this.deleteFile,
    required this.cacheSizeNotifier,
    required this.clearCache,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: AnimatedBuilder(
          animation: controller,
          builder: (BuildContext context, Widget? child) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ValueListenableBuilder(
                      valueListenable: cacheSizeNotifier,
                      builder: (context, cacheSize, child) => AutoSizeText(
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
                    if (cacheSizeNotifier.value != "0.00 B")
                      ElevatedButton(
                        onPressed: clearCache,
                        child: Text(context.ispectL10n.clearCache),
                      ),
                  ],
                ),
              ),
              const Gap(10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.ispectL10n.appData,
                          style: context.ispectTheme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          context.ispectL10n.totalFilesCount(controller.files.length),
                          style: context.ispectTheme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(top: 10.0),
                  itemCount: controller.files.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 0),
                  itemBuilder: (BuildContext ctx, i) {
                    final f = controller.files[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 10,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              "$i. File:\n ${f.path}",
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
