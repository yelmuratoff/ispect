import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';
import 'package:ispect/src/features/ispect/presentation/screens/navigation_flow.dart';

part 'collapsed_body.dart';

class LogCard extends StatelessWidget {
  const LogCard({
    required this.icon,
    required this.color,
    required this.data,
    required this.index,
    required this.isExpanded,
    required this.onTap,
    this.observer,
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
  final ISpectNavigatorObserver? observer;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          color:
              isExpanded ? color.withValues(alpha: 0.08) : Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LogCardHeader(
                icon: icon,
                color: color,
                data: data,
                isExpanded: isExpanded,
                onTap: onTap,
                onCopyTap: onCopyTap,
                observer: observer,
              ),
              if (isExpanded) ...[
                _ExpandedContent(
                  data: data,
                  color: color,
                ),
              ],
            ],
          ),
        ),
      );
}

class _LogCardHeader extends StatelessWidget {
  const _LogCardHeader({
    required this.icon,
    required this.color,
    required this.data,
    required this.isExpanded,
    required this.onTap,
    required this.observer,
    this.onCopyTap,
  });

  final IconData icon;
  final Color color;
  final ISpectifyData data;
  final bool isExpanded;
  final VoidCallback onTap;
  final VoidCallback? onCopyTap;
  final ISpectNavigatorObserver? observer;

  @override
  Widget build(BuildContext context) => Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: CollapsedBody(
              icon: icon,
              color: color,
              title: data.key,
              dateTime: data.formattedTime,
              onCopyTap: onCopyTap,
              onRouteTap: data.isRouteLog && observer != null
                  ? () => ISpectNavigationFlowScreen(
                        observer: observer!,
                        log: data as RouteLog,
                      ).push(context)
                  : null,
              onHttpTap: () => JsonScreen(
                data: data.toJson(),
                truncatedData: data.toJson(truncated: true),
              ).push(context),
              message: data.textMessage,
              errorMessage: data.httpLogText,
              expanded: isExpanded,
            ),
          ),
        ),
      );
}

class _ExpandedContent extends StatelessWidget {
  const _ExpandedContent({
    required this.data,
    required this.color,
  });

  final ISpectifyData data;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final hasStackTrace = data.stackTraceLogText?.isNotEmpty ?? false;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 1,
          color: context.ispectTheme.dividerColor,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LazyExpandedBody(
                data: data,
                color: color,
                hasStackTrace: hasStackTrace,
              ),
              if (hasStackTrace)
                _LazyStackTraceBody(
                  color: color,
                  stackTrace: data.stackTraceLogText!,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Displays expanded content for log entries with conditional styling and text sections
class _LazyExpandedBody extends StatelessWidget {
  const _LazyExpandedBody({
    required this.data,
    required this.color,
    required this.hasStackTrace,
  });

  final ISpectifyData data;
  final Color color;
  final bool hasStackTrace;

  @override
  Widget build(BuildContext context) => _LogContentContainer(
        hasStackTrace: hasStackTrace,
        color: color,
        child: _LogTextContent(
          message: data.textMessage,
          type: data.typeText,
          errorMessage: data.httpLogText,
          isHTTP: data.isHttpLog,
          textStyle: TextStyle(
            color: color,
            fontSize: 12,
          ),
        ),
      );
}

class _LazyStackTraceBody extends StatelessWidget {
  const _LazyStackTraceBody({
    required this.color,
    required this.stackTrace,
  });

  final String stackTrace;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: SizedBox(
          width: double.maxFinite,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              border: Border.all(color: color),
            ),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: SelectableText(
                stackTrace,
                maxLines: 50,
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
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Show message only if conditions are met
          if (message != null && !isHTTP && errorMessage == null)
            SelectableText(message!, style: textStyle),

          // Show type if available
          if (type != null) SelectableText(type!, style: textStyle),

          // Show error message if available
          if (errorMessage != null)
            SelectableText(errorMessage!, style: textStyle),
        ],
      );
}
