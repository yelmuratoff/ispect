import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/utils/copy_clipboard.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';

/// Detail view widget for displaying selected log data.
///
/// When [correlatedLog] is provided, shows a banner allowing
/// navigation to the correlated request/response.
class LogDetailView extends StatelessWidget {
  const LogDetailView({
    required this.activeData,
    this.onClose,
    this.correlatedLog,
    this.correlationDuration,
    this.onNavigateToCorrelated,
    this.onShowRelated,
    super.key,
  });

  final ISpectLogData activeData;
  final VoidCallback? onClose;
  final ISpectLogData? correlatedLog;
  final Duration? correlationDuration;
  final VoidCallback? onNavigateToCorrelated;
  final void Function(String id)? onShowRelated;

  void push(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (routeContext) {
          final showRelated = onShowRelated;
          return Scaffold(
            body: SafeArea(
              child: LogDetailView(
                activeData: activeData,
                correlatedLog: correlatedLog,
                correlationDuration: correlationDuration,
                onNavigateToCorrelated: onNavigateToCorrelated,
                onClose: () {
                  onClose?.call();
                  Navigator.of(routeContext).pop();
                },
                onShowRelated: showRelated == null
                    ? null
                    : (id) {
                        showRelated(id);
                        Navigator.of(routeContext).pop();
                      },
              ),
            ),
          );
        },
        settings: const RouteSettings(name: 'ISpect Log Detail'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final json = activeData.toJson();
    final corrId =
        activeData.additionalData?[TraceKeys.correlationId] as String?;
    final txnId =
        activeData.additionalData?[TraceKeys.transactionId] as String?;
    final hasTraceCorrelation = (corrId != null || txnId != null) &&
        !(correlatedLog != null && onNavigateToCorrelated != null);

    return Column(
      children: [
        if (correlatedLog != null && onNavigateToCorrelated != null)
          _CorrelationBanner(
            activeData: activeData,
            correlatedLog: correlatedLog!,
            duration: correlationDuration,
            onNavigate: onNavigateToCorrelated!,
          ),
        if (hasTraceCorrelation)
          _TraceCorrelationBanner(
            correlationId: corrId,
            transactionId: txnId,
            onShowRelated: onShowRelated,
          ),
        Expanded(
          child: RepaintBoundary(
            child: JsonScreen(
              key: ValueKey(activeData.id),
              data: json,
              truncatedData: activeData.toJson(truncated: true),
              onClose: onClose,
            ),
          ),
        ),
      ],
    );
  }
}

class _TraceCorrelationBanner extends StatelessWidget {
  const _TraceCorrelationBanner({
    this.correlationId,
    this.transactionId,
    this.onShowRelated,
  });

  final String? correlationId;
  final String? transactionId;
  final void Function(String id)? onShowRelated;

  static void _copyId(BuildContext context, String id) {
    copyClipboard(
      context,
      value: id,
      title: ISpectLocalization.of(context).correlationIdCopied,
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = context.appTheme.colorScheme.tertiary;
    final chips = <Widget>[];

    if (correlationId != null) {
      chips.add(
        _IdChip(
          label: 'Corr',
          value: correlationId!,
          color: color,
          actionIcon: onShowRelated != null
              ? Icons.filter_list_rounded
              : Icons.copy_rounded,
          onTap: onShowRelated != null
              ? () => onShowRelated!(correlationId!)
              : () => _copyId(context, correlationId!),
        ),
      );
    }
    if (transactionId != null) {
      chips.add(
        _IdChip(
          label: 'Txn',
          value: transactionId!,
          color: color,
          actionIcon: onShowRelated != null
              ? Icons.filter_list_rounded
              : Icons.copy_rounded,
          onTap: onShowRelated != null
              ? () => onShowRelated!(transactionId!)
              : () => _copyId(context, transactionId!),
        ),
      );
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        border: Border(
          bottom: BorderSide(
            color: color.withValues(alpha: 0.15),
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            Icon(
              Icons.link_rounded,
              size: 14,
              color: color.withValues(alpha: 0.7),
            ),
            const Gap(6),
            Expanded(
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: chips,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IdChip extends StatelessWidget {
  const _IdChip({
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
    this.actionIcon = Icons.copy_rounded,
  });

  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;
  final IconData actionIcon;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.all(Radius.circular(6)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      '$label: $value',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  if (onTap != null) ...[
                    const Gap(4),
                    Icon(
                      actionIcon,
                      size: 11,
                      color: color,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
}

class _CorrelationBanner extends StatelessWidget {
  const _CorrelationBanner({
    required this.activeData,
    required this.correlatedLog,
    required this.onNavigate,
    this.duration,
  });

  final ISpectLogData activeData;
  final ISpectLogData correlatedLog;
  final Duration? duration;
  final VoidCallback onNavigate;

  @override
  Widget build(BuildContext context) {
    final isViewingRequest = activeData.key == ISpectLogType.httpRequest.key;
    final l10n = ISpectLocalization.of(context);
    final theme = context.iSpect.theme;

    final targetLabel = isViewingRequest ? l10n.httpResponse : l10n.httpRequest;
    final targetKey = isViewingRequest
        ? ISpectLogType.httpResponse.key
        : ISpectLogType.httpRequest.key;
    final targetColor = theme.getTypeColor(context, key: targetKey) ??
        context.appTheme.colorScheme.primary;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: targetColor.withValues(alpha: 0.06),
        border: Border(
          bottom: BorderSide(
            color: targetColor.withValues(alpha: 0.15),
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            Icon(
              Icons.link_rounded,
              size: 14,
              color: targetColor.withValues(alpha: 0.7),
            ),
            const Gap(6),
            if (duration != null) ...[
              _DurationChip(duration: duration!),
              const Gap(8),
            ],
            Expanded(
              child: Text(
                correlatedLog.message ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.appTheme.textColor.withValues(alpha: 0.6),
                  fontSize: 11,
                ),
              ),
            ),
            const Gap(8),
            _GoToButton(
              label: targetLabel,
              color: targetColor,
              onTap: onNavigate,
            ),
          ],
        ),
      ),
    );
  }
}

class _DurationChip extends StatelessWidget {
  const _DurationChip({required this.duration});

  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final text = duration.inMilliseconds < 1000
        ? '${duration.inMilliseconds}ms'
        : '${(duration.inMilliseconds / 1000).toStringAsFixed(1)}s';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.appTheme.textColor.withValues(alpha: 0.08),
        borderRadius: const BorderRadius.all(Radius.circular(4)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        child: Text(
          text,
          style: TextStyle(
            color: context.appTheme.textColor.withValues(alpha: 0.5),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}

class _GoToButton extends StatelessWidget {
  const _GoToButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.all(Radius.circular(6)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Gap(4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 12,
                    color: color,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
