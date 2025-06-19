import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ispect/src/common/observers/route_observer.dart';
import 'package:ispect/src/common/observers/transition.dart';
import 'package:ispect/src/common/utils/screen_size.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';

class ISpectNavigationFlowScreen extends StatefulWidget {
  const ISpectNavigationFlowScreen({required this.observer, super.key});

  final ISpectNavigatorObserver observer;

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
          title: const Text('Navigation Flow'),
          leading: IconButton(
            onPressed: Navigator.of(context).pop,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        ),
        body: _items.isEmpty
            ? const Center(
                child: Text(
                  'No navigation transitions recorded',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
            : context.screenSizeWhen<Widget>(
                phone: () => _NavigationFlowList(items: _items),
                tablet: () => _NavigationFlowGrid(
                  items: _items,
                  maxItemWidth: 200,
                  aspectRatio: 1.5,
                ),
                desktop: () => _NavigationFlowGrid(
                  items: _items,
                  maxItemWidth: 220,
                  aspectRatio: 1.8,
                ),
              ),
      );
}

class _NavigationFlowList extends StatelessWidget {
  const _NavigationFlowList({required this.items});

  final List<RouteTransition> items;

  @override
  Widget build(BuildContext context) => ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        itemBuilder: (context, index) => ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 100),
          child: _NavigationTransitionCard(
            transition: items[index],
            index: index,
            totalItems: items.length,
          ),
        ),
      );
}

class _NavigationFlowGrid extends StatelessWidget {
  const _NavigationFlowGrid({
    required this.items,
    required this.maxItemWidth,
    required this.aspectRatio,
  });

  final List<RouteTransition> items;
  final double maxItemWidth;
  final double aspectRatio;

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
          ),
        ),
      );
}

class _NavigationTransitionCard extends StatelessWidget {
  const _NavigationTransitionCard({
    required this.transition,
    required this.index,
    required this.totalItems,
  });

  final RouteTransition transition;
  final int index;
  final int totalItems;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSpecial = index == 0 || index == totalItems - 1;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (isSpecial) _buildSpecialIndicator(context),
            Row(
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

  Widget _buildSpecialIndicator(BuildContext context) {
    final theme = Theme.of(context);
    final isCurrent = index == 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              isCurrent ? '📍' : '🏁',
              style: const TextStyle(fontSize: 10),
            ),
          ),
          const Gap(4),
          Flexible(
            child: Text(
              isCurrent ? 'Current' : 'Start',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
