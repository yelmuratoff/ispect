part of '../monitor_info_page.dart';

class _MonitorView extends StatelessWidget {
  final String typeName;

  final List<TalkerData> logs;
  final ISpectOptions options;
  final void Function(BuildContext, TalkerData)? onCopyTap;
  final void Function() onReverseLogsOrder;
  final void Function() toggleLogsExpansion;
  final bool isLogsExpanded;
  const _MonitorView({
    required this.typeName,
    required this.logs,
    required this.options,
    required this.onCopyTap,
    required this.onReverseLogsOrder,
    required this.isLogsExpanded,
    required this.toggleLogsExpansion,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            typeName,
            style: const TextStyle(fontSize: 18),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.swap_vert_rounded),
              onPressed: onReverseLogsOrder,
            ),
            IconButton(
              icon: Icon(
                isLogsExpanded
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
              onPressed: toggleLogsExpansion,
            ),
          ],
        ),
        body: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: SizedBox(height: 10)),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final data = logs[index];
                  return TalkerDataCards(
                    data: data,
                    onCopyTap: () => onCopyTap?.call(context, data),
                    color: getTypeColor(
                      isDark: context.isDarkMode,
                      key: data.title,
                    ),
                    expanded: isLogsExpanded,
                    backgroundColor: context.ispectTheme.cardColor,
                  );
                },
                childCount: logs.length,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 10)),
          ],
        ),
      );
}
