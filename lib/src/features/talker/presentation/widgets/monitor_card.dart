part of '../pages/monitor/talker_monitor_page.dart';

class _TalkerMonitorsCard extends StatelessWidget {
  const _TalkerMonitorsCard({
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
                        size: 20,
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
                                fontSize: 16,
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