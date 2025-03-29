part of 'log_card.dart';

class _ExpandedBody extends StatelessWidget {
  const _ExpandedBody({
    required this.stackTrace,
    required this.widget,
    required this.expanded,
    required this.type,
    required this.message,
    required this.errorMessage,
    required this.isHTTP,
  });

  final String? stackTrace;
  final ISpectLogCard widget;
  final bool expanded;
  final String? message;
  final String? type;
  final String? errorMessage;
  final bool isHTTP;

  @override
  Widget build(BuildContext context) {
    if (!expanded) return const SizedBox.shrink();

    return Container(
      width: double.maxFinite,
      padding: stackTrace != null ? const EdgeInsets.all(6) : EdgeInsets.zero,
      decoration: stackTrace != null
          ? BoxDecoration(
              border: Border.all(color: widget.color),
              borderRadius: const BorderRadius.all(Radius.circular(10)),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message != null && !isHTTP && errorMessage == null)
            _buildSelectable(message!),
          if (type != null) _buildSelectable(type!),
          if (errorMessage != null) _buildSelectable(errorMessage!),
        ],
      ),
    );
  }

  Widget _buildSelectable(String text) => SelectableText(
        text,
        style: TextStyle(
          color: widget.color,
          fontSize: 12,
        ),
      );
}
