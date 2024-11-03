part of 'log_card.dart';

class _CollapsedBody extends StatelessWidget {
  const _CollapsedBody({
    required this.icon,
    required this.color,
    required this.title,
    required this.dateTime,
    required this.onCopyTap,
    required this.onHttpTap,
    required this.isHttpLog,
    required this.message,
    required this.errorMessage,
    required this.expanded,
  });

  final IconData icon;
  final Color color;
  final String? title;
  final String dateTime;
  final VoidCallback? onCopyTap;
  final VoidCallback? onHttpTap;
  final bool isHttpLog;
  final String? message;
  final String? errorMessage;
  final bool expanded;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      icon,
                      color: color,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$title | $dateTime',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const Gap(2),
                if (message != null && !expanded)
                  Text(
                    message!,
                    maxLines: expanded ? 200 : 2,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                    ),
                  ),
                if (message == 'FlutterErrorDetails' && !expanded)
                  Text(
                    errorMessage.toString(),
                    maxLines: 2,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox.square(
            dimension: 18,
            child: IconButton(
              padding: EdgeInsets.zero,
              iconSize: 18,
              icon: Icon(
                Icons.copy_rounded,
                color: color,
              ),
              onPressed: onCopyTap,
            ),
          ),
          if (isHttpLog) ...[
            const Gap(8),
            SizedBox.square(
              dimension: 18,
              child: IconButton(
                padding: EdgeInsets.zero,
                iconSize: 18,
                icon: Icon(
                  Icons.zoom_out_map_rounded,
                  color: color,
                ),
                onPressed: onHttpTap,
              ),
            ),
          ],
        ],
      );
}
