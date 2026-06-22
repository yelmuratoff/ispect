import 'package:flutter/material.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/utils/squircle.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';
import 'package:ispect/src/core/res/constants/ispect_constants.dart';
import 'package:ispect/src/features/json_viewer/models/node_view_model.dart';

class BreadcrumbBar extends StatefulWidget {
  const BreadcrumbBar({
    required this.node,
    required this.onSegmentTap,
  });

  final NodeViewModelState node;
  final ValueChanged<NodeViewModelState> onSegmentTap;

  @override
  State<BreadcrumbBar> createState() => BreadcrumbBarState();
}

class BreadcrumbBarState extends State<BreadcrumbBar> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scheduleScrollToEnd();
  }

  @override
  void didUpdateWidget(BreadcrumbBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.node != widget.node) {
      _scheduleScrollToEnd();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scheduleScrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    });
  }

  List<NodeViewModelState> _buildPath(NodeViewModelState node) {
    final path = <NodeViewModelState>[];
    NodeViewModelState? current = node;
    while (current != null) {
      path.add(current);
      current = current.parent;
    }
    return path.reversed.toList();
  }

  @override
  Widget build(BuildContext context) {
    final path = _buildPath(widget.node);
    final onSurface = context.appTheme.colorScheme.onSurface;
    final mutedColor = onSurface.withValues(alpha: 0.25);
    final activeColor = onSurface.withValues(alpha: 0.95);

    final chipColor = context.ispectCardColor;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: DecoratedBox(
        decoration: ISpectSquircle.decoration(
          color: chipColor,
          radius: ISpectConstants.largeBorderRadius,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: SizedBox(
            height: 22,
            child: Row(
              children: [
                Icon(
                  Icons.account_tree_outlined,
                  size: 13,
                  color: mutedColor,
                ),
                const Gap(8),
                Expanded(
                  child: ListView.separated(
                    controller: _scrollController,
                    physics: const ClampingScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                    itemCount: path.length,
                    separatorBuilder: (_, __) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 13,
                        color: mutedColor,
                      ),
                    ),
                    itemBuilder: (context, index) {
                      final segment = path[index];
                      final isLast = index == path.length - 1;
                      return Material(
                        type: MaterialType.transparency,
                        child: InkWell(
                          onTap: () => widget.onSegmentTap(segment),
                          borderRadius:
                              const BorderRadius.all(Radius.circular(4)),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsetsGeometry.symmetric(
                                horizontal: 4,
                              ),
                              child: Text(
                                segment.key,
                                style: TextStyle(
                                  fontSize: isLast ? 11 : 10,
                                  fontWeight: isLast
                                      ? FontWeight.w700
                                      : FontWeight.w300,
                                  color: isLast ? activeColor : mutedColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
