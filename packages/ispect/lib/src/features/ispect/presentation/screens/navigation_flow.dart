import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/observers/transition.dart';
import 'package:ispect/src/common/utils/screen_size.dart';
import 'package:ispect/src/features/ispect/presentation/widgets/navigation_flow/actions_sheet.dart';
import 'package:ispect/src/features/ispect/presentation/widgets/navigation_flow/navigation_transition_card.dart';

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
  late final List<RouteTransition> _items;

  @override
  void initState() {
    super.initState();
    _items = widget.observer.transitions.reversed.toList();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(context.ispectL10n.navigationFlow),
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          actionsPadding: const EdgeInsets.only(right: 12),
          actions: [
            IconButton(
              icon: const Icon(
                Icons.more_horiz_rounded,
              ),
              onPressed: () {
                ISpectNavigationFlowActionsSheet(
                  items: _items,
                  transition: null,
                  log: widget.log,
                ).show(context);
              },
            ),
          ],
        ),
        body: _items.isEmpty
            ? Center(
                child: Text(
                  context.ispectL10n.noNavigationTransitions,
                  style: context.ispectTheme.textTheme.bodyLarge?.copyWith(
                    color: context.ispectTheme.colorScheme.onSurface
                        .withValues(alpha: 0.5),
                  ),
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
  final String? selectedTransitionId;
  final RouteLog? log;

  @override
  Widget build(BuildContext context) => ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        itemBuilder: (context, index) => ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 120),
          child: NavigationTransitionCard(
            transition: items[index],
            index: index,
            totalItems: items.length,
            log: log,
            selectedTransitionId: selectedTransitionId,
            items: items,
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
  final String? selectedTransitionId;
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
          itemBuilder: (context, index) => NavigationTransitionCard(
            transition: items[index],
            index: index,
            totalItems: items.length,
            log: log,
            selectedTransitionId: selectedTransitionId,
            items: items,
          ),
        ),
      );
}
