part of '../monitor_info_page.dart';

class _MonitorView extends StatelessWidget {
  const _MonitorView({
    required this.typeName,
    required this.logs,
    required this.options,
    required this.onCopyTap,
    required this.onReverseLogsOrder,
    required this.isLogsExpanded,
    required this.toggleLogsExpansion,
  });
  final String typeName;

  final List<TalkerData> logs;
  final ISpectOptions options;
  final void Function(BuildContext context, TalkerData data)? onCopyTap;
  final VoidCallback onReverseLogsOrder;
  final VoidCallback toggleLogsExpansion;
  final bool isLogsExpanded;

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
          SliverList.separated(
            itemCount: logs.length,
            separatorBuilder: (_, __) => Divider(
              color: iSpect.theme.dividerColor(context),
              thickness: 1,
            ),
            itemBuilder: (context, index) {
              final data = logs[index];
              return ISpectLogCard(
                data: data,
                onCopyTap: () => onCopyTap?.call(context, data),
                color: iSpect.theme.getTypeColor(
                  context,
                  key: data.key,
                ),
                expanded: isLogsExpanded,
                backgroundColor: context.ispectTheme.cardColor,
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 10)),
        ],
      ),
    );
  }
}
