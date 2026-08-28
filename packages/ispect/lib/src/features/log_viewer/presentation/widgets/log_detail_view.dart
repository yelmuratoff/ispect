import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/utils/copy_clipboard.dart';
import 'package:ispect/src/common/utils/squircle.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';
import 'package:ispect/src/common/widgets/ispect_theme_scope.dart';
import 'package:ispect/src/core/res/constants/ispect_constants.dart';

/// Detail view widget for displaying selected log data.
///
/// When [correlatedLog] is provided, shows a banner allowing
/// navigation to the correlated request/response.
class LogDetailView extends StatefulWidget {
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
          return ISpectThemeScope(
            child: Scaffold(
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
            ),
          );
        },
        settings: const RouteSettings(name: 'ISpect Log Detail'),
      ),
    );
  }

  @override
  State<LogDetailView> createState() => _LogDetailViewState();
}

class _LogDetailViewState extends State<LogDetailView> {
  late bool _redactionActive;
  late RedactionService _redactionService;
  late int _redactionRevision;
  late String _correlatedMessage;
  late ({String display, String raw})? _correlationId;
  late ({String display, String raw})? _transactionId;
  late bool _isViewingRequest;
  late JsonScreen _jsonScreen;

  DiagnosticResourceLimits get _resourceLimits =>
      ISpect.loggerIfInitialized?.options.resourceLimits ??
      DiagnosticResourceLimits.balanced;

  @override
  void initState() {
    super.initState();
    _refreshSnapshots();
  }

  @override
  void didUpdateWidget(covariant LogDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentRedactionService = ISpectRedaction.service;
    if (!identical(oldWidget.activeData, widget.activeData) ||
        !identical(oldWidget.correlatedLog, widget.correlatedLog) ||
        _redactionActive != ISpectRedaction.enabled ||
        !identical(_redactionService, currentRedactionService) ||
        _redactionRevision != currentRedactionService.configurationRevision) {
      _refreshSnapshots();
    }
  }

  void _refreshSnapshots() {
    _redactionActive = ISpectRedaction.enabled;
    _redactionService = ISpectRedaction.service;
    _redactionRevision = _redactionService.configurationRevision;
    final activeData = captureISpectLogDataForEgress(widget.activeData);
    final correlatedLog = widget.correlatedLog;
    _correlatedMessage = correlatedLog == null
        ? ''
        : _viewerText(captureISpectLogDataForEgress(correlatedLog).message);
    final correlationId = activeData.additionalData?[TraceKeys.correlationId];
    final transactionId = activeData.additionalData?[TraceKeys.transactionId];
    _correlationId = _viewerTraceId(
      correlationId is String ? correlationId : null,
    );
    _transactionId = _viewerTraceId(
      transactionId is String ? transactionId : null,
    );
    _isViewingRequest = activeData.key == ISpectLogType.httpRequest.key;
    final json = _viewerSnapshot();
    _jsonScreen = JsonScreen(
      key: UniqueKey(),
      data: json,
      truncatedData: _viewerSnapshot(truncated: true),
      onClose: _handleClose,
    );
  }

  Map<String, dynamic> _viewerSnapshot({bool truncated = false}) {
    final prepared = widget.activeData.toExportJson(
      redactionActive: _redactionActive,
      truncated: truncated,
    );
    if (!_redactionActive) return prepared;

    try {
      final redacted = _redactionService.redactEnvelopeForExport(
        prepared,
        rootValueKeys: const {'key'},
        resourceLimits: _resourceLimits,
      );
      if (redacted is Map<String, Object?>) {
        return Map<String, dynamic>.from(redacted);
      }
    } on Object {
      return const <String, dynamic>{
        'message': JsonValueNormalizer.unprintableValue,
      };
    }
    return const <String, dynamic>{
      'message': JsonValueNormalizer.unprintableValue,
    };
  }

  ({String display, String raw})? _viewerTraceId(String? value) =>
      value == null ? null : (display: _viewerText(value), raw: value);

  String _viewerText(Object? value) {
    if (value == null) return '';
    try {
      final prepared = _redactionActive
          ? _redactionService.redactForExport(
              value,
              resourceLimits: _resourceLimits,
            )
          : LogExportOutput.boundJsonValue(
              value,
              resourceLimits: _resourceLimits,
            );
      return switch (prepared) {
        final String text => text,
        final bool value => value.toString(),
        final num value => value.toString(),
        _ => defaultPlaceholder,
      };
    } on Object {
      return defaultPlaceholder;
    }
  }

  void _handleClose() {
    final callback = widget.onClose;
    if (callback != null) {
      callback();
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final hasTraceCorrelation =
        (_correlationId != null || _transactionId != null) &&
        !(widget.correlatedLog != null &&
            widget.onNavigateToCorrelated != null);

    return Column(
      children: [
        if (widget.correlatedLog != null &&
            widget.onNavigateToCorrelated != null)
          _CorrelationBanner(
            isViewingRequest: _isViewingRequest,
            correlatedMessage: _correlatedMessage,
            duration: widget.correlationDuration,
            onNavigate: widget.onNavigateToCorrelated!,
          ),
        if (hasTraceCorrelation)
          _TraceCorrelationBanner(
            correlationId: _correlationId,
            transactionId: _transactionId,
            onShowRelated: widget.onShowRelated,
          ),
        Expanded(child: RepaintBoundary(child: _jsonScreen)),
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

  final ({String display, String raw})? correlationId;
  final ({String display, String raw})? transactionId;
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
          value: correlationId!.display,
          color: color,
          actionIcon: onShowRelated != null
              ? Icons.filter_list_rounded
              : Icons.copy_rounded,
          onTap: onShowRelated != null
              ? () => onShowRelated!(correlationId!.raw)
              : () => _copyId(context, correlationId!.display),
        ),
      );
    }
    if (transactionId != null) {
      chips.add(
        _IdChip(
          label: 'Txn',
          value: transactionId!.display,
          color: color,
          actionIcon: onShowRelated != null
              ? Icons.filter_list_rounded
              : Icons.copy_rounded,
          onTap: onShowRelated != null
              ? () => onShowRelated!(transactionId!.raw)
              : () => _copyId(context, transactionId!.display),
        ),
      );
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        border: Border(
          bottom: BorderSide(color: color.withValues(alpha: 0.15)),
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
            Expanded(child: Wrap(spacing: 6, runSpacing: 4, children: chips)),
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
        decoration: ISpectSquircle.decoration(
          color: color.withValues(alpha: 0.1),
          radius: ISpectConstants.mediumBorderRadius,
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
                Icon(actionIcon, size: 11, color: color),
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
    required this.isViewingRequest,
    required this.correlatedMessage,
    required this.onNavigate,
    this.duration,
  });

  final bool isViewingRequest;
  final String correlatedMessage;
  final Duration? duration;
  final VoidCallback onNavigate;

  @override
  Widget build(BuildContext context) {
    final l10n = ISpectLocalization.of(context);
    final theme = context.iSpect.theme;

    final targetLabel = isViewingRequest ? l10n.httpResponse : l10n.httpRequest;
    final targetKey = isViewingRequest
        ? ISpectLogType.httpResponse.key
        : ISpectLogType.httpRequest.key;
    final targetColor =
        theme.getTypeColor(context, key: targetKey) ??
        context.ispectPrimaryColor;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: targetColor.withValues(alpha: 0.06),
        border: Border(
          bottom: BorderSide(color: targetColor.withValues(alpha: 0.15)),
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
                correlatedMessage,
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
      decoration: ISpectSquircle.decoration(
        color: context.appTheme.textColor.withValues(alpha: 0.08),
        radius: ISpectConstants.smallBorderRadius,
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
        decoration: ISpectSquircle.decoration(
          color: color.withValues(alpha: 0.1),
          radius: ISpectConstants.mediumBorderRadius,
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
              Icon(Icons.arrow_forward_rounded, size: 12, color: color),
            ],
          ),
        ),
      ),
    ),
  );
}
