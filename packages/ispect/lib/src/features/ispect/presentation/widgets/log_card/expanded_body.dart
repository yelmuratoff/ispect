part of 'log_card.dart';

/// Displays expanded content for log entries with conditional styling and text sections
class _ExpandedBody extends StatelessWidget {
  const _ExpandedBody({
    required this.stackTrace,
    required this.owner,
    required this.expanded,
    required this.type,
    required this.message,
    required this.errorMessage,
    required this.isHTTP,
  });

  final String? stackTrace;
  final ISpectLogCard owner;
  final bool expanded;
  final String? message;
  final String? type;
  final String? errorMessage;
  final bool isHTTP;

  @override
  Widget build(BuildContext context) {
    if (!expanded) return const SizedBox.shrink();

    return _LogContentContainer(
      hasStackTrace: stackTrace != null,
      color: owner.color,
      child: _LogTextContent(
        message: message,
        type: type,
        errorMessage: errorMessage,
        isHTTP: isHTTP,
        textStyle: TextStyle(
          color: owner.color,
          fontSize: 12,
        ),
      ),
    );
  }
}

/// Container widget that handles decoration based on stack trace presence
class _LogContentContainer extends StatelessWidget {
  const _LogContentContainer({
    required this.hasStackTrace,
    required this.color,
    required this.child,
  });

  final bool hasStackTrace;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.maxFinite,
        child: DecoratedBox(
          decoration: hasStackTrace
              ? BoxDecoration(
                  border: Border.all(color: color),
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                )
              : const BoxDecoration(),
          child: Padding(
            padding: hasStackTrace ? const EdgeInsets.all(6) : EdgeInsets.zero,
            child: child,
          ),
        ),
      );
}

/// Handles the display logic for different types of log text content
class _LogTextContent extends StatelessWidget {
  const _LogTextContent({
    required this.message,
    required this.type,
    required this.errorMessage,
    required this.isHTTP,
    required this.textStyle,
  });

  final String? message;
  final String? type;
  final String? errorMessage;
  final bool isHTTP;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    final widgets = <Widget>[];

    if (message != null && !isHTTP && errorMessage == null) {
      widgets.add(SelectableText(message!, style: textStyle));
    }
    if (type != null) {
      widgets.add(SelectableText(type!, style: textStyle));
    }
    if (errorMessage != null) {
      widgets.add(SelectableText(errorMessage!, style: textStyle));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}
