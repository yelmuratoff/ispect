part of 'log_card.dart';

class _CollapsedBody extends StatelessWidget {
  const _CollapsedBody({
    required this.icon,
    required this.color,
    required this.title,
    required this.dateTime,
    required this.onCopyTap,
    required this.onHttpTap,
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
                    Flexible(
                      child: Text(
                        '$title | $dateTime',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                if (!expanded) ..._buildMessageSection(),
              ],
            ),
          ),
          SizedBox.square(
            dimension: 24,
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
          const Gap(4),
          SizedBox.square(
            dimension: 24,
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
      );

  List<Widget> _buildMessageSection() {
    if (message != null && message != 'FlutterErrorDetails') {
      return [
        const Gap(2),
        Text(
          message!,
          maxLines: 2,
          style: TextStyle(
            color: color,
            fontSize: 12,
          ),
        ),
      ];
    } else if (message == 'FlutterErrorDetails') {
      return [
        const Gap(2),
        Text(
          errorMessage ?? '',
          maxLines: 2,
          style: TextStyle(
            color: color,
            fontSize: 12,
          ),
        ),
      ];
    }
    return const [];
  }
}
