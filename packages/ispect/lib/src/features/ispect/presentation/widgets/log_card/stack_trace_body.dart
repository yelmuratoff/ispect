part of 'log_card.dart';

class _StrackTraceBody extends StatelessWidget {
  const _StrackTraceBody({
    required this.widget,
    required String? stackTrace,
  }) : _stackTrace = stackTrace;

  final ISpectLogCard widget;
  final String? _stackTrace;

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
                BorderSide(color: widget.color),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: SelectableText(
                _stackTrace!,
                maxLines: 100,
                minLines: 1,
                style: TextStyle(
                  color: widget.color,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
      );
}
