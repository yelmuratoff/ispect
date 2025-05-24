import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/utils/screen_size.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';

class ISpectLogsInfoBottomSheet extends StatefulWidget {
  const ISpectLogsInfoBottomSheet({super.key});

  @override
  State<ISpectLogsInfoBottomSheet> createState() =>
      _ISpectLogsInfoBottomSheetState();
}

class _ISpectLogsInfoBottomSheetState extends State<ISpectLogsInfoBottomSheet> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => context.screenSizeMaybeWhen(
        phone: () => DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) => _Body(
            scrollController: scrollController,
          ),
        ),
        orElse: () => AlertDialog(
          contentPadding: EdgeInsets.zero,
          backgroundColor: context.ispectTheme.scaffoldBackgroundColor,
          content: SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.7,
            width: MediaQuery.sizeOf(context).width * 0.8,
            child: _Body(
              scrollController: _scrollController,
            ),
          ),
        ),
      );
}

class _Body extends StatelessWidget {
  const _Body({
    required this.scrollController,
  });

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final theme = context.ispectTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.all(
          Radius.circular(16),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: _InfoDescription(
            iSpect: ISpect.read(context),
            scrollController: scrollController,
          ),
        ),
      ),
    );
  }
}

class _InfoDescription extends StatelessWidget {
  const _InfoDescription({
    required this.iSpect,
    required this.scrollController,
  });

  final ISpectScopeModel iSpect;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final logCategories = _getLogCategories(context, iSpect);

    return Column(
      children: [
        _Header(title: context.ispectL10n.iSpectifyLogsInfo),
        const Gap(16),
        Expanded(
          child: Scrollbar(
            controller: scrollController,
            interactive: true,
            thumbVisibility: true,
            child: ListView.separated(
              controller: scrollController,
              itemCount: logCategories.length,
              separatorBuilder: (_, __) => const Gap(16),
              itemBuilder: (context, index) {
                final category = logCategories.entries.elementAt(index);
                return _CategorySection(
                  title: category.key,
                  logs: category.value,
                  iSpect: iSpect,
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Map<String, List<LogDescription>> _getLogCategories(
    BuildContext context,
    ISpectScopeModel iSpect,
  ) {
    final descriptions = iSpect.theme.descriptions(context);

    final categories = <String, List<LogDescription>>{};

    for (final log in descriptions) {
      final category = _getCategory(log.key, context);
      categories.putIfAbsent(category, () => []).add(log);
    }

    return categories;
  }

  String _getCategory(String logKey, BuildContext context) {
    final l10n = context.ispectL10n;

    if (logKey.startsWith('http')) return l10n.iSpectifyTypeHttp;
    if (logKey.startsWith('bloc')) return l10n.iSpectifyTypeBloc;
    if (logKey.startsWith('riverpod')) return l10n.iSpectifyTypeRiverpod;

    return l10n.common;
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = context.ispectTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style:
              theme.textTheme.headlineSmall?.copyWith(color: theme.textColor),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          visualDensity: VisualDensity.compact,
          icon: Icon(Icons.close_rounded, color: theme.textColor),
        ),
      ],
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.title,
    required this.logs,
    required this.iSpect,
  });

  final String title;
  final List<LogDescription> logs;
  final ISpectScopeModel iSpect;

  @override
  Widget build(BuildContext context) {
    final theme = context.ispectTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: theme.textColor,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Gap(8),
        ...logs.map((log) => _LogItem(log: log, iSpect: iSpect)),
      ],
    );
  }
}

class _LogItem extends StatelessWidget {
  const _LogItem({required this.log, required this.iSpect});

  final LogDescription log;
  final ISpectScopeModel iSpect;

  @override
  Widget build(BuildContext context) {
    final theme = context.ispectTheme;
    final typeColor = iSpect.theme.getTypeColor(context, key: log.key);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '${log.key}: ',
              style: TextStyle(color: typeColor, fontWeight: FontWeight.w500),
            ),
            TextSpan(
              text: log.description,
              style: TextStyle(color: theme.textColor),
            ),
          ],
        ),
      ),
    );
  }
}
