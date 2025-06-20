import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/observers/transition.dart';
import 'package:ispect/src/common/utils/screen_size.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';
import 'package:ispect/src/features/ispect/presentation/widgets/log_card/log_card.dart';
import 'package:ispect/src/features/json_viewer/json_screen.dart';

class ISpectNavigationFlowScreen extends StatefulWidget {
  const ISpectNavigationFlowScreen({
    required this.observer,
    this.log,
    super.key,
  });

  final ISpectNavigatorObserver observer;
  final RouteLog? log;

  void push(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => this,
        settings: RouteSettings(
          name: 'ISpect Navigation Flow Screen',
          arguments: log != null
              ? {
                  'id': log?.transitionId,
                }
              : null,
        ),
      ),
    );
  }

  @override
  State<ISpectNavigationFlowScreen> createState() =>
      _ISpectNavigationFlowScreenState();
}

class _ISpectNavigationFlowScreenState
    extends State<ISpectNavigationFlowScreen> {
  final List<RouteTransition> _items = [];

  @override
  void initState() {
    super.initState();
    _items.addAll(widget.observer.transitions.reversed);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(context.ispectL10n.navigationFlow),
          leading: IconButton(
            onPressed: Navigator.of(context).pop,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        ),
        body: _items.isEmpty
            ? Center(
                child: Text(
                  context.ispectL10n.noNavigationTransitions,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
            : context.screenSizeWhen<Widget>(
                phone: () => _NavigationFlowList(
                  items: _items,
                  selectedTransitionId: widget.log?.transitionId,
                  log: widget.log,
                ),
                tablet: () => _NavigationFlowGrid(
                  items: _items,
                  maxItemWidth: 200,
                  aspectRatio: 1.5,
                  selectedTransitionId: widget.log?.transitionId,
                  log: widget.log,
                ),
                desktop: () => _NavigationFlowGrid(
                  items: _items,
                  maxItemWidth: 220,
                  aspectRatio: 1.8,
                  selectedTransitionId: widget.log?.transitionId,
                  log: widget.log,
                ),
              ),
      );
}

class _NavigationFlowList extends StatelessWidget {
  const _NavigationFlowList({
    required this.items,
    this.selectedTransitionId,
    this.log,
  });

  final List<RouteTransition> items;
  final int? selectedTransitionId;
  final RouteLog? log;

  @override
  Widget build(BuildContext context) => ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        itemBuilder: (context, index) => ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 120),
          child: _NavigationTransitionCard(
            transition: items[index],
            index: index,
            totalItems: items.length,
            log: log,
            selectedTransitionId: selectedTransitionId,
          ),
        ),
      );
}

class _NavigationFlowGrid extends StatelessWidget {
  const _NavigationFlowGrid({
    required this.items,
    required this.maxItemWidth,
    required this.aspectRatio,
    this.selectedTransitionId,
    this.log,
  });

  final List<RouteTransition> items;
  final double maxItemWidth;
  final double aspectRatio;
  final int? selectedTransitionId;
  final RouteLog? log;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => GridView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: items.length,
          cacheExtent: 400,
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: maxItemWidth,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: aspectRatio,
          ),
          itemBuilder: (context, index) => _NavigationTransitionCard(
            transition: items[index],
            index: index,
            totalItems: items.length,
            log: log,
            selectedTransitionId: selectedTransitionId,
          ),
        ),
      );
}

class _NavigationTransitionCard extends StatelessWidget {
  const _NavigationTransitionCard({
    required this.transition,
    required this.index,
    required this.totalItems,
    this.selectedTransitionId,
    this.log,
  });

  final RouteLog? log;
  final RouteTransition transition;
  final int index;
  final int totalItems;
  final int? selectedTransitionId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSpecial = index == 0 || index == totalItems - 1;
    final isSelected = selectedTransitionId == transition.id;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (isSpecial || isSelected)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                spacing: 4,
                children: [
                  Flexible(child: _buildSpecialIndicator(context)),
                  if (log != null)
                    SquareIconButton(
                      icon: Icons.zoom_out_map_rounded,
                      color: theme.colorScheme.primary,
                      onPressed: () {
                        JsonScreen(
                          data: log!.toJson(),
                        ).push(context);
                      },
                    ),
                ],
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    transition.transitionText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: isSpecial ? FontWeight.w600 : FontWeight.w500,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (log != null && !(isSelected || isSpecial))
                  SquareIconButton(
                    icon: Icons.zoom_out_map_rounded,
                    color: theme.colorScheme.primary,
                    onPressed: () {
                      JsonScreen(
                        data: log!.toJson(),
                      ).push(context);
                    },
                  ),
              ],
            ),
            Flexible(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      DateFormat('dd.MM.yy, HH:mm:ss')
                          .format(transition.timestamp),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecialIndicator(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: context.ispectTheme.colorScheme.primaryContainer,
          borderRadius: const BorderRadius.all(Radius.circular(8)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                _headerIcon(),
                style: const TextStyle(fontSize: 10),
              ),
            ),
            const Gap(4),
            Flexible(
              flex: 10,
              child: Text(
                _headerText(context),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.ispectTheme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.ispectTheme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
      );

  String _headerIcon() {
    if (index == 0) {
      return '📍'; // Current
    } else if (index == totalItems - 1) {
      return '🏁'; // Start
    }
    return '🔄'; // Transition
  }

  String _headerText(BuildContext context) {
    if (index == 0) {
      return context.ispectL10n.current;
    } else if (index == totalItems - 1) {
      return context.ispectL10n.start;
    }
    return context.ispectL10n.selectedTransition;
  }
}
