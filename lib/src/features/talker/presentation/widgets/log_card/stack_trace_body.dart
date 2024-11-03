part of 'log_card.dart';

class _StrackTraceBody extends StatelessWidget {
  const _StrackTraceBody({
    required this.widget,
    required String? stackTrace,
  }) : _stackTrace = stackTrace;

  final ISpectLogCard widget;
  final String? _stackTrace;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          border: Border.fromBorderSide(
            BorderSide(color: widget.color),
          ),
        ),
        child: Text(
          _stackTrace!,
          maxLines: 100,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: widget.color,
            fontSize: 12,
          ),
        ),
      );
}
