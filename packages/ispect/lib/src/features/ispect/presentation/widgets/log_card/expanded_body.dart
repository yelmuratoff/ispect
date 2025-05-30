part of 'log_card.dart';

/// Displays expanded content for log entries with conditional styling and text sections
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

    return _LogContentContainer(
      hasStackTrace: stackTrace != null,
      color: widget.color,
      child: _LogTextContent(
        message: message,
        type: type,
        errorMessage: errorMessage,
        isHTTP: isHTTP,
        textStyle: _createTextStyle(),
      ),
    );
  }

  TextStyle _createTextStyle() => TextStyle(
        color: widget.color,
        fontSize: 12,
      );
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
  Widget build(BuildContext context) => Container(
        width: double.maxFinite,
        padding: hasStackTrace ? const EdgeInsets.all(6) : EdgeInsets.zero,
        decoration: hasStackTrace ? _createDecoration() : null,
        child: child,
      );

  BoxDecoration _createDecoration() => BoxDecoration(
        border: Border.all(color: color),
        borderRadius: const BorderRadius.all(Radius.circular(10)),
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
    final textWidgets = _buildTextWidgets();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: textWidgets,
    );
  }

  List<Widget> _buildTextWidgets() {
    final widgets = <Widget>[];

    _addMessageIfApplicable(widgets);
    _addTextIfNotNull(widgets, type);
    _addTextIfNotNull(widgets, errorMessage);

    return widgets;
  }

  void _addMessageIfApplicable(List<Widget> widgets) {
    if (_shouldShowMessage()) {
      _addTextIfNotNull(widgets, message);
    }
  }

  bool _shouldShowMessage() =>
      message != null && !isHTTP && errorMessage == null;

  void _addTextIfNotNull(List<Widget> widgets, String? text) {
    if (text != null) {
      widgets.add(SelectableText(text, style: textStyle));
    }
  }
}
