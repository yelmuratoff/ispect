import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/controllers/ispect_view_controller.dart';
import 'package:ispect/src/common/utils/screen_size.dart';
import 'package:ispect/src/features/ispect/presentation/widgets/log_card/desktop_log_row.dart';
import 'package:ispect/src/features/ispect/presentation/widgets/log_card/log_card.dart';

/// A widget that represents a single log entry in the list.
class LogListItem extends StatelessWidget {
  const LogListItem({
    required this.logData,
    required this.itemIndex,
    required this.statusIcon,
    required this.statusColor,
    required this.isExpanded,
    required this.onItemTapped,
    required this.onSharePressed,
    this.observer,
    this.onOpenDetail,
    this.onShowRelated,
    this.onTypeFilterTap,
    this.useRelativeTime = false,
    this.typeColumnWidth = 100,
    this.timeColumnWidth = 100,
    this.searchMatchState = SearchMatchState.none,
    super.key,
  });

  final ISpectLogData logData;
  final int itemIndex;
  final IconData statusIcon;
  final Color statusColor;
  final bool isExpanded;
  final VoidCallback onItemTapped;
  final VoidCallback onSharePressed;
  final ISpectNavigatorObserver? observer;
  final VoidCallback? onOpenDetail;
  final void Function(String id)? onShowRelated;
  final void Function(String type)? onTypeFilterTap;
  final bool useRelativeTime;
  final double typeColumnWidth;
  final double timeColumnWidth;
  final SearchMatchState searchMatchState;

  @override
  Widget build(BuildContext context) {
    final logBuilder = ISpect.read(context).options.logBuilder;
    if (logBuilder != null) {
      return logBuilder(context, logData);
    }

    if (context.screenSize.isDesktop) {
      return DesktopLogRow(
        icon: statusIcon,
        color: statusColor,
        data: logData,
        index: itemIndex,
        isSelected: isExpanded,
        searchMatchState: searchMatchState,
        onShareTap: onSharePressed,
        onTap: onItemTapped,
        onOpenDetail: onOpenDetail,
        onTypeFilterTap: onTypeFilterTap,
        observer: observer,
        useRelativeTime: useRelativeTime,
        typeColumnWidth: typeColumnWidth,
        timeColumnWidth: timeColumnWidth,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      child: LogCard(
        icon: statusIcon,
        color: statusColor,
        data: logData,
        index: itemIndex,
        isExpanded: isExpanded,
        searchMatchState: searchMatchState,
        onShareTap: onSharePressed,
        onTap: onItemTapped,
        observer: observer,
        onShowRelated: onShowRelated,
      ),
    );
  }
}
