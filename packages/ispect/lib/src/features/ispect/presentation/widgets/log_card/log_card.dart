// ignore_for_file: implementation_imports

import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';
import 'package:ispect/src/features/ispect/presentation/pages/http/detailed_http_page.dart';
import 'package:ispect/src/features/ispect/presentation/widgets/base_card.dart';

part 'collapsed_body.dart';
part 'expanded_body.dart';
part 'stack_trace_body.dart';

class ISpectLogCard extends StatefulWidget {
  const ISpectLogCard({
    required this.data,
    required this.color,
    super.key,
    this.onCopyTap,
    this.onTap,
    this.expanded = true,
    this.margin,
    this.backgroundColor = const Color.fromARGB(255, 49, 49, 49),
  });

  final ISpectiyData data;
  final VoidCallback? onCopyTap;
  final VoidCallback? onTap;
  final bool expanded;
  final EdgeInsets? margin;
  final Color color;
  final Color backgroundColor;

  @override
  State<ISpectLogCard> createState() => _ISpectifyDataCardState();
}

class _ISpectifyDataCardState extends State<ISpectLogCard> {
  late bool _expanded;
  late String? _stackTrace;

  late String? _errorMessage;
  late String? _type;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeValues();
  }

  void _initializeValues() {
    _expanded = widget.expanded;
    _stackTrace = _getStackTrace;

    _errorMessage = _getErrorMessage;
    _type = _getType;
  }

  @override
  Widget build(BuildContext context) {
    final iSpect = ISpect.read(context);
    return Padding(
      padding: widget.margin ?? EdgeInsets.zero,
      child: GestureDetector(
        onTap: _onTap,
        child: ISpectBaseCard(
          color: widget.color,
          backgroundColor: widget.backgroundColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CollapsedBody(
                icon: iSpect.theme.logIcons[widget.data.key] ??
                    Icons.bug_report_outlined,
                color: widget.color,
                title: widget.data.key,
                dateTime: widget.data.formattedTime,
                onCopyTap: widget.onCopyTap,
                onHttpTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => DetailedHTTPPage(data: widget.data),
                      settings: RouteSettings(
                        name: 'Detailed HTTP Page',
                        arguments: widget.data,
                      ),
                    ),
                  );
                },
                isHttpLog: _isHttpLog,
                message: widget.data.textMessage,
                errorMessage: _errorMessage,
                expanded: _expanded,
              ),
              if (_expanded)
                _ExpandedBody(
                  stackTrace: _stackTrace,
                  widget: widget,
                  expanded: _expanded,
                  type: _type,
                  message: widget.data.textMessage,
                  errorMessage: _errorMessage,
                ),
              if (_expanded && _stackTrace != null && _stackTrace!.isNotEmpty)
                _StrackTraceBody(
                  widget: widget,
                  stackTrace: _stackTrace,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _onTap() {
    if (widget.onTap != null) {
      widget.onTap?.call();
      return;
    }
    setState(() {
      _expanded = !_expanded;
    });
  }

  String? get _getStackTrace {
    if ((widget.data is ISpectifyError ||
            widget.data is ISpectifyException ||
            widget.data.message == 'FlutterErrorDetails') &&
        widget.data.stackTrace != null &&
        widget.data.stackTrace.toString().isNotEmpty) {
      return 'StackTrace:\n${widget.data.stackTrace}';
    }
    return null;
  }

  bool get _isHttpLog => [
        ISpectifyLogType.httpRequest.key,
        ISpectifyLogType.httpResponse.key,
        ISpectifyLogType.httpError.key,
      ].contains(widget.data.key);

  String? get _getErrorMessage {
    var txt = widget.data.exception?.toString();

    if ((txt?.isNotEmpty ?? false) && txt!.contains('Source stack:')) {
      txt = 'Data: ${txt.split('Source stack:').first.replaceAll('\n', '')}';
    }
    final isHttpLog = [
      ISpectifyLogType.httpRequest.key,
      ISpectifyLogType.httpResponse.key,
      ISpectifyLogType.httpError.key,
    ].contains(widget.data.key);
    if (isHttpLog) {
      return widget.data.textMessage;
    }
    return txt;
  }

  String? get _getType {
    if (widget.data is! ISpectifyError && widget.data is! ISpectifyException) {
      return null;
    }
    return 'Type: ${widget.data.exception?.runtimeType.toString() ?? widget.data.error?.runtimeType.toString() ?? ''}';
  }
}
