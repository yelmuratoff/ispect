import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
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
    this.customItemBuilder,
    this.observer,
    this.onOpenDetail,
    this.onTypeFilterTap,
    this.useRelativeTime = false,
    this.typeColumnWidth = 70,
    this.timeColumnWidth = 140,
    super.key,
  });

  final ISpectLogData logData;
  final int itemIndex;
  final IconData statusIcon;
  final Color statusColor;
  final bool isExpanded;
  final VoidCallback onItemTapped;
  final VoidCallback onSharePressed;
  final ISpectLogDataBuilder? customItemBuilder;
  final ISpectNavigatorObserver? observer;
  final VoidCallback? onOpenDetail;
  final void Function(String type)? onTypeFilterTap;
  final bool useRelativeTime;
  final double typeColumnWidth;
  final double timeColumnWidth;

  @override
  Widget build(BuildContext context) {
    if (customItemBuilder != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: customItemBuilder!(context, logData),
      );
    }

    if (context.screenSize.isDesktop) {
      return DesktopLogRow(
        icon: statusIcon,
        color: statusColor,
        data: logData,
        index: itemIndex,
        isSelected: isExpanded,
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
        onShareTap: onSharePressed,
        onTap: onItemTapped,
        observer: observer,
      ),
    );
  }
}
