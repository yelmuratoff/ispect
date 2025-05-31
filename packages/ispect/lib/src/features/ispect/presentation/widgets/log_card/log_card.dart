import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';
import 'package:ispect/src/features/ispect/presentation/screens/log_screen.dart';

part 'collapsed_body.dart';

class LogCard extends StatelessWidget {
  const LogCard({
    required this.icon,
    required this.color,
    required this.data,
    required this.index,
    required this.isExpanded,
    required this.onTap,
    this.onCopyTap,
    super.key,
  });
  final ISpectifyData data;
  final IconData icon;
  final Color color;
  final int index;
  final bool isExpanded;
  final VoidCallback onTap;
  final VoidCallback? onCopyTap;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: isExpanded ? color.withValues(alpha: 0.1) : Colors.transparent,
        child: Column(
          children: [
            ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              visualDensity: VisualDensity.compact,
              title: CollapsedBody(
                icon: icon,
                color: color,
                title: data.key,
                dateTime: data.formattedTime,
                onCopyTap: onCopyTap,
                onHttpTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => LogScreen(data: data),
                    settings: const RouteSettings(
                      name: 'Detailed Log Screen',
                    ),
                  ),
                ),
                message: data.textMessage,
                errorMessage: data.httpLogText,
                expanded: isExpanded,
              ),
              onTap: onTap,
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: 8,
                ),
                child: Column(
                  children: [
                    if (isExpanded)
                      _ExpandedBody(
                        stackTrace: data.stackTraceLogText,
                        expanded: isExpanded,
                        type: data.typeText,
                        color: color,
                        message: data.textMessage,
                        errorMessage: data.httpLogText,
                        isHTTP: data.isHttpLog,
                      ),
                    if (isExpanded &&
                        data.stackTraceLogText != null &&
                        data.stackTraceLogText!.isNotEmpty)
                      _StrackTraceBody(
                        color: color,
                        stackTrace: data.stackTraceLogText,
                      ),
                  ],
                ),
              ),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
              reverseDuration: const Duration(milliseconds: 200),
            ),
          ],
        ),
      );
}

/// Displays expanded content for log entries with conditional styling and text sections
class _ExpandedBody extends StatelessWidget {
  const _ExpandedBody({
    required this.stackTrace,
    required this.color,
    required this.expanded,
    required this.type,
    required this.message,
    required this.errorMessage,
    required this.isHTTP,
  });

  final String? stackTrace;
  final Color color;
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
      color: color,
      child: _LogTextContent(
        message: message,
        type: type,
        errorMessage: errorMessage,
        isHTTP: isHTTP,
        textStyle: TextStyle(
          color: color,
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

class _StrackTraceBody extends StatelessWidget {
  const _StrackTraceBody({
    required this.color,
    required String? stackTrace,
  }) : _stackTrace = stackTrace;

  final String? _stackTrace;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: SizedBox(
          width: double.maxFinite,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(
                Radius.circular(10),
              ),
              border: Border.fromBorderSide(
                BorderSide(color: color),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: SelectableText(
                _stackTrace!,
                maxLines: 100,
                minLines: 1,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
      );
}
