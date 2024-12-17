// ignore_for_file: implementation_imports

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/features/talker/presentation/pages/http/detailed_http_page.dart';
import 'package:ispect/src/features/talker/presentation/widgets/base_card.dart';
import 'package:talker_flutter/src/ui/theme/default_theme.dart';
import 'package:talker_flutter/talker_flutter.dart';

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
    this.backgroundColor = defaultCardBackgroundColor,
  });

  final TalkerData data;
  final VoidCallback? onCopyTap;
  final VoidCallback? onTap;
  final bool expanded;
  final EdgeInsets? margin;
  final Color color;
  final Color backgroundColor;

  @override
  State<ISpectLogCard> createState() => _TalkerDataCardState();
}

class _TalkerDataCardState extends State<ISpectLogCard> {
  late bool _expanded;
  late String? _stackTrace;
  late String? _message;
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
    _message = _getMessage;
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
                title: widget.data.title,
                dateTime: widget.data.displayTime(),
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
                isHttpLog: (widget.data.key?.contains('http') ?? false) ||
                    (widget.data.title?.contains('http') ?? false),
                message: _message,
                errorMessage: _errorMessage,
                expanded: _expanded,
              ),
              if (_expanded)
                _ExpandedBody(
                  stackTrace: _stackTrace,
                  widget: widget,
                  expanded: _expanded,
                  type: _type,
                  message: _message,
                  errorMessage: _errorMessage,
                  // riverpodFullLog: _riverpodFullLog,
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
    if ((widget.data is TalkerError ||
            widget.data is TalkerException ||
            widget.data.message == 'FlutterErrorDetails') &&
        widget.data.stackTrace != null &&
        widget.data.stackTrace.toString().isNotEmpty) {
      return 'StackTrace:\n${widget.data.stackTrace}';
    }
    return null;
  }

  String? get _getMessage {
    if (widget.data is TalkerError || widget.data is TalkerException) {
      return widget.data.message;
    }
    final isHttpLog = [
      TalkerLogType.httpError.key,
      TalkerLogType.httpRequest.key,
      TalkerLogType.httpResponse.key,
    ].contains(widget.data.title);
    if (isHttpLog) {
      return widget.data.generateTextMessage();
    }
    return widget.data.displayMessage;
  }

  String? get _getErrorMessage {
    var txt = widget.data.exception?.toString();

    if ((txt?.isNotEmpty ?? false) && txt!.contains('Source stack:')) {
      txt = 'Data: ${txt.split('Source stack:').first.replaceAll('\n', '')}';
    }
    final isHttpLog = [
      TalkerLogType.httpError.key,
    ].contains(widget.data.title);
    if (isHttpLog) {
      return widget.data.generateTextMessage();
    }
    return txt;
  }

  String? get _getType {
    if (widget.data is! TalkerError && widget.data is! TalkerException) {
      return null;
    }
    return 'Type: ${widget.data.exception?.runtimeType.toString() ?? widget.data.error?.runtimeType.toString() ?? ''}';
  }

  // String? get _riverpodFullLog {
  //   final data = widget.data;

  //   if (data is RiverpodUpdateLog) {
  //     return 'Detailed: \nPREVIOUS state: ${data.previousValue} \nNEW state: ${data.newValue}';
  //   } else if (data is RiverpodAddLog) {
  //     return 'Detailed: \nINITIAL state: ${data.value}';
  //   } else if (data is RiverpodDisposeLog) {
  //     return 'Detailed: \nDISPOSED';
  //   } else if (data is RiverpodFailLog) {
  //     return 'Detailed: \nError: ${data.error} \nStackTrace: ${data.exception}';
  //   }

  //   return null;
  // }
}
