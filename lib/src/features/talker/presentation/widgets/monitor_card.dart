import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/features/talker/presentation/widgets/base_card.dart';
import 'package:talker_flutter/talker_flutter.dart';

class ISpectMonitorCard extends StatelessWidget {
  const ISpectMonitorCard({
    required this.logs,
    required this.title,
    required this.color,
    required this.icon,
    this.subtitle,
    this.subtitleWidget,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final Widget? subtitleWidget;
  final List<TalkerData> logs;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: ISpectBaseCard(
            color: color,
            backgroundColor: context.ispectTheme.cardColor,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        icon,
                        color: color,
                        size: 24,
                      ),
                      const Gap(10),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                color: color,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (subtitle != null)
                              Text(
                                subtitle!,
                                style: context.ispectTheme.textTheme.bodyMedium,
                              ),
                            if (subtitleWidget != null) subtitleWidget!,
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (onTap != null)
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: color,
                    size: 16,
                  ),
              ],
            ),
          ),
        ),
      );
}
