part of 'log_card.dart';

class _ExpandedBody extends StatelessWidget {
  const _ExpandedBody({
    required String? stackTrace,
    required this.widget,
    required bool expanded,
    required String? type,
    required String? message,
    required String? errorMessage,
    // required String? riverpodFullLog,
  })  : _stackTrace = stackTrace,
        _expanded = expanded,
        _type = type,
        _message = message,
        _errorMessage = errorMessage;
  // _riverpodFullLog = riverpodFullLog;

  final String? _stackTrace;
  final ISpectLogCard widget;
  final bool _expanded;
  final String? _message;
  final String? _type;
  final String? _errorMessage;
  // final String? _riverpodFullLog;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: _stackTrace != null ? const EdgeInsets.only(top: 8) : null,
        padding:
            _stackTrace != null ? const EdgeInsets.all(6) : EdgeInsets.zero,
        decoration: _stackTrace != null
            ? BoxDecoration(
                border: Border.fromBorderSide(
                  BorderSide(color: widget.color),
                ),
                borderRadius: const BorderRadius.all(Radius.circular(10)),
              )
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_expanded && _message != null)
              Text(
                _message!,
                style: TextStyle(
                  color: widget.color,
                  fontSize: 12,
                ),
              ),
            if (_expanded && _type != null)
              Text(
                _type!,
                style: TextStyle(
                  color: widget.color,
                  fontSize: 12,
                ),
              ),
            if (_expanded && _errorMessage != null)
              Text(
                _errorMessage!,
                style: TextStyle(
                  color: widget.color,
                  fontSize: 12,
                ),
              ),
            // if (_expanded && _riverpodFullLog != null)
            //   Text(
            //     _riverpodFullLog!,
            //     style: TextStyle(
            //       color: widget.color,
            //       fontSize: 12,
            //     ),
            //   ),
          ],
        ),
      );
}
