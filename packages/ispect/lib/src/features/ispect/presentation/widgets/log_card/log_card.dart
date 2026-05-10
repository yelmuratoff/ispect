import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/controllers/ispect_view_controller.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/utils/decoration_utils.dart';
import 'package:ispect/src/common/utils/severity_bar.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';
import 'package:ispect/src/common/widgets/slow_badge.dart';
import 'package:ispect/src/core/res/constants/ispect_constants.dart';
import 'package:ispect/src/features/ispect/presentation/screens/navigation_flow.dart';
import 'package:ispect/src/features/ispect/presentation/widgets/log_card/log_context_menu.dart';
import 'package:ispect/src/features/ispect/presentation/widgets/log_detail_view.dart';

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
    this.onShareTap,
    this.onShowRelated,
    this.searchMatchState = SearchMatchState.none,
    super.key,
  });

  final ISpectLogData data;
  final IconData icon;
  final Color color;
  final int index;
  final bool isExpanded;
  final VoidCallback onTap;
  final VoidCallback? onShareTap;
  final ISpectNavigatorObserver? observer;
  final void Function(String id)? onShowRelated;
  final SearchMatchState searchMatchState;

  @override
  Widget build(BuildContext context) {
    final cardColor = context.ispectTheme.card?.resolve(context) ??
        context.appTheme.cardColor;

    final primaryColor = context.appTheme.colorScheme.primary;
    final isFocused = searchMatchState == SearchMatchState.focused;
    final isMatch = searchMatchState == SearchMatchState.match;

    final defaultBorder =
        context.appTheme.colorScheme.onSurface.withValues(alpha: 0.06);
    final sev = severityBar(data);
    final accentColor = color.withValues(
      alpha: isExpanded ? 0.9 : sev.alpha,
    );

    final Color effectiveBg;
    final Color effectiveBorder;
    final double borderWidth;
    final List<BoxShadow>? boxShadow;

    if (isFocused) {
      effectiveBg = primaryColor.withValues(alpha: 0.12);
      effectiveBorder = primaryColor;
      borderWidth = 2;
      boxShadow = [
        BoxShadow(
          color: primaryColor.withValues(alpha: 0.25),
          blurRadius: 10,
          spreadRadius: 1,
        ),
      ];
    } else if (isMatch) {
      effectiveBg = primaryColor.withValues(alpha: 0.06);
      effectiveBorder = primaryColor.withValues(alpha: 0.5);
      borderWidth = 1.5;
      boxShadow = null;
    } else {
      effectiveBg = cardColor;
      effectiveBorder = defaultBorder;
      borderWidth = 1;
      boxShadow = null;
    }

    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: effectiveBg,
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          border: Border.all(
            color: effectiveBorder,
            width: borderWidth,
          ),
          boxShadow: boxShadow,
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: accentColor,
                  width: isExpanded ? sev.width + 1 : sev.width,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _LogCardHeader(
                  icon: icon,
                  color: color,
                  data: data,
                  isExpanded: isExpanded,
                  onTap: onTap,
                  onShareTap: onShareTap,
                  observer: observer,
                  onShowRelated: onShowRelated,
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: isExpanded
                      ? _ExpandedContent(data: data, color: color)
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LogCardHeader extends StatelessWidget {
  const _LogCardHeader({
    required this.icon,
    required this.color,
    required this.data,
    required this.isExpanded,
    required this.onTap,
    required this.observer,
    this.onShareTap,
    this.onShowRelated,
  });

  final IconData icon;
  final Color color;
  final ISpectLogData data;
  final bool isExpanded;
  final VoidCallback onTap;
  final VoidCallback? onShareTap;
  final ISpectNavigatorObserver? observer;
  final void Function(String id)? onShowRelated;

  String get _message {
    final msg = data.isHttpLog ? data.httpLogText : data.textMessage;
    return msg ?? '';
  }

  @override
  Widget build(BuildContext context) {
    void openDetail() {
      LogDetailView(
        activeData: data,
        onClose: () => Navigator.of(context).pop(),
        onShowRelated: onShowRelated != null
            ? (id) {
                onShowRelated!(id);
                Navigator.of(context).pop();
              }
            : null,
      ).push(context);
    }

    void openMenu(Offset position) {
      showLogContextMenu(
        context: context,
        position: position,
        data: data,
        message: _message,
        onShareTap: onShareTap,
        onOpenDetail: openDetail,
        onNavigationFlowTap: data.isRouteLog && observer != null
            ? () => ISpectNavigationFlowScreen(
                  observer: observer!,
                  log: data,
                ).push(context)
            : null,
      );
    }

    return Semantics(
      button: true,
      expanded: isExpanded,
      label:
          '${ISpectLogType.fromKey(data.key ?? '')?.displayTitle ?? data.key ?? "Log"}: $_message',
      onTap: onTap,
      child: Material(
        type: MaterialType.transparency,
        child: GestureDetector(
          excludeFromSemantics: true,
          onLongPressStart: (details) => openMenu(details.globalPosition),
          child: InkWell(
            excludeFromSemantics: true,
            onTap: onTap,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(10),
              bottomRight: Radius.circular(10),
            ),
            child: ColoredBox(
              color: isExpanded
                  ? color.withValues(alpha: 0.08)
                  : Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 6, 6),
                child: CollapsedBody(
                  icon: icon,
                  color: color,
                  title: ISpectLogType.fromKey(data.key ?? '')?.displayTitle ??
                      data.key,
                  dateTime: data.formattedTime,
                  subtitle: _buildSubtitle(data),
                  message: data.textMessage,
                  errorMessage: data.httpLogText,
                  expanded: isExpanded,
                  statusCode: data.httpStatusCode,
                  slowDurationMs:
                      (data.traceSlow ?? false) ? data.traceDurationMs : null,
                  onExpandTap: openDetail,
                  onMenuTap: () => openMenu(Offset.zero),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Builds the subtitle line shown beneath the title row when a log card is
/// expanded.
String? _buildSubtitle(ISpectLogData data) {
  final parts = <String>['#${_shortId(data.id)}'];

  final source = data.traceSource;
  if (source != null && source.isNotEmpty) parts.add(source);

  final op = data.traceOperation;
  final target = data.traceTarget;
  if (op != null && target != null) {
    parts.add('$op $target');
  } else if (op != null) {
    parts.add(op);
  } else if (target != null) {
    parts.add(target);
  }

  final ms = data.traceDurationMs;
  if (ms != null) parts.add(_formatTraceDuration(ms));

  final raised = data.exception ?? data.error;
  if (raised != null) {
    final typeName = raised.runtimeType.toString();
    if (typeName.isNotEmpty && typeName != 'Null') {
      final clean = typeName.startsWith('_') ? typeName.substring(1) : typeName;
      parts.add(clean);
    }
  }

  if (parts.length == 1) {
    final levelName = data.logLevel?.name;
    if (levelName != null) {
      final title =
          ISpectLogType.fromKey(data.key ?? '')?.displayTitle ?? data.key ?? '';
      if (title.toLowerCase() != levelName.toLowerCase()) {
        parts.add(levelName.toUpperCase());
      }
    }
  }

  return parts.join(' · ');
}

String _formatTraceDuration(int ms) {
  if (ms < 1000) return '${ms}ms';
  return '${(ms / 1000).toStringAsFixed(1)}s';
}

/// Trims a ULID down to a copy-friendly visual stub. The full id stays in
/// JSON exports for cross-session lookup; the UI just needs something short
/// and visually distinct.
String _shortId(String id) => id.length <= 6 ? id : id.substring(id.length - 6);

class _ExpandedContent extends StatelessWidget {
  const _ExpandedContent({
    required this.data,
    required this.color,
  });

  final ISpectLogData data;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final hasStackTrace = data.stackTraceLogText?.isNotEmpty ?? false;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Divider(
          height: 1,
          color: color.withValues(alpha: 0.1),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
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

  final ISpectLogData data;
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
            decoration: DecorationUtils.roundedBorder(color: color),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: SelectableText(
                stackTrace,
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
              ? DecorationUtils.roundedBorder(color: color)
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
