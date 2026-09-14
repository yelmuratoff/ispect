import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/utils/squircle.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';

class NetworkPayloadPreview extends StatelessWidget {
  const NetworkPayloadPreview({
    required this.payload,
    required this.color,
    required this.maxStringLength,
    super.key,
  });

  final NetworkLogPayload payload;
  final Color color;
  final int maxStringLength;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (payload.hasBody)
        _BodyPreview(
          body: payload.body,
          color: color,
          maxStringLength: maxStringLength,
        ),
      if (payload.hasBody && payload.hasHeaders) const Gap(6),
      if (payload.hasHeaders)
        _HeadersDisclosure(
          headers: payload.headers,
          color: color,
          maxStringLength: maxStringLength,
        ),
    ],
  );
}

class _BodyPreview extends StatefulWidget {
  const _BodyPreview({
    required this.body,
    required this.color,
    required this.maxStringLength,
  });

  final Object? body;
  final Color color;
  final int maxStringLength;

  @override
  State<_BodyPreview> createState() => _BodyPreviewState();
}

class _BodyPreviewState extends State<_BodyPreview> {
  static const _maxLines = 20;

  Object? _formattedSource;
  int _formattedMaxStringLength = -1;
  String _formattedBody = '';

  String _formatBody() {
    if (!identical(_formattedSource, widget.body) ||
        _formattedMaxStringLength != widget.maxStringLength) {
      _formattedSource = widget.body;
      _formattedMaxStringLength = widget.maxStringLength;
      _formattedBody = JsonTruncator.pretty(
        widget.body,
        maxStringLength: widget.maxStringLength,
      );
    }
    return _formattedBody;
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color;
    final formattedBody = _formatBody();
    final bodyStyle = TextStyle(
      color: context.appTheme.textColor.withValues(alpha: 0.78),
      fontSize: 11,
      height: 1.35,
      fontFamily: 'monospace',
    );

    return DecoratedBox(
      decoration: ISpectSquircle.decoration(
        color: context.appTheme.textColor.withValues(alpha: 0.035),
        side: BorderSide(color: color.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.ispectL10n.data,
              style: TextStyle(
                color: color.withValues(alpha: 0.8),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Gap(4),
            LayoutBuilder(
              builder: (context, constraints) {
                final bodyText = Text(
                  formattedBody,
                  maxLines: _maxLines,
                  overflow: TextOverflow.clip,
                  style: bodyStyle,
                );
                if (!constraints.hasBoundedWidth) return bodyText;

                final textPainter = TextPainter(
                  text: TextSpan(text: formattedBody, style: bodyStyle),
                  maxLines: _maxLines,
                  textDirection: Directionality.of(context),
                  textScaler: MediaQuery.textScalerOf(context),
                  locale: Localizations.maybeLocaleOf(context),
                )..layout(maxWidth: constraints.maxWidth);
                final isTruncated = textPainter.didExceedMaxLines;
                textPainter.dispose();

                if (!isTruncated) return bodyText;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShaderMask(
                      blendMode: BlendMode.dstIn,
                      shaderCallback: (bounds) => LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0, 0.72, 1],
                        colors: [
                          context.appTheme.textColor,
                          context.appTheme.textColor,
                          context.appTheme.textColor.withValues(alpha: 0),
                        ],
                      ).createShader(bounds),
                      child: bodyText,
                    ),
                    const Gap(4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(
                          Icons.more_horiz_rounded,
                          size: 14,
                          color: color.withValues(alpha: 0.65),
                        ),
                        const Gap(4),
                        Flexible(
                          child: Text(
                            context.ispectL10n.previewTruncated,
                            textAlign: TextAlign.end,
                            style: TextStyle(
                              color: context.appTheme.textColor.withValues(
                                alpha: 0.58,
                              ),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HeadersDisclosure extends StatefulWidget {
  const _HeadersDisclosure({
    required this.headers,
    required this.color,
    required this.maxStringLength,
  });

  final Map<String, Object?> headers;
  final Color color;
  final int maxStringLength;

  @override
  State<_HeadersDisclosure> createState() => _HeadersDisclosureState();
}

class _HeadersDisclosureState extends State<_HeadersDisclosure> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final label = '${context.ispectL10n.headers} (${widget.headers.length})';
    final shape = ISpectSquircle.border();

    return DecoratedBox(
      decoration: ISpectSquircle.decoration(
        color: context.appTheme.textColor.withValues(alpha: 0.025),
        side: BorderSide(color: widget.color.withValues(alpha: 0.1)),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              button: true,
              expanded: _expanded,
              label: label,
              onTap: _toggle,
              child: InkWell(
                excludeFromSemantics: true,
                customBorder: shape,
                onTap: _toggle,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: kMinInteractiveDimension,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.http_rounded,
                          size: 14,
                          color: widget.color.withValues(alpha: 0.7),
                        ),
                        const Gap(6),
                        Expanded(
                          child: Text(
                            label,
                            style: TextStyle(
                              color: context.appTheme.textColor.withValues(
                                alpha: 0.72,
                              ),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Icon(
                          _expanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 17,
                          color: widget.color.withValues(alpha: 0.55),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            AnimatedSize(
              duration: ISpectMotion.short,
              curve: ISpectMotion.standardCurve,
              alignment: Alignment.topCenter,
              child: _expanded
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                      child: SelectableText(
                        JsonTruncator.pretty(
                          widget.headers,
                          maxStringLength: widget.maxStringLength,
                        ),
                        style: TextStyle(
                          color: context.appTheme.textColor.withValues(
                            alpha: 0.76,
                          ),
                          fontSize: 10.5,
                          height: 1.35,
                          fontFamily: 'monospace',
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  void _toggle() => setState(() => _expanded = !_expanded);
}
