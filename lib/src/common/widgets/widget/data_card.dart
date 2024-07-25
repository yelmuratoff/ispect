// ignore_for_file: implementation_imports

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:ispect/src/features/talker/detailed_http_page.dart';
import 'package:talker_flutter/src/ui/theme/default_theme.dart';
import 'package:talker_flutter/src/ui/widgets/base_card.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:talker_riverpod_logger/talker_riverpod_logger.dart';

class TalkerDataCards extends StatefulWidget {
  const TalkerDataCards({
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
  State<TalkerDataCards> createState() => _TalkerDataCardState();
}

class _TalkerDataCardState extends State<TalkerDataCards> {
  var _expanded = false;

  @override
  void initState() {
    super.initState();
    _expanded = widget.expanded;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _expanded = widget.expanded;
  }

  @override
  void didUpdateWidget(covariant TalkerDataCards oldWidget) {
    super.didUpdateWidget(oldWidget);
    _expanded = widget.expanded;
  }

  @override
  Widget build(BuildContext context) {
    final errorMessage = _errorMessage;
    final errorType = _type;
    final message = _message;
    final stackTrace = _stackTrace;
    final riverpodFullLog = _riverpodFullLog;
    return Padding(
      padding: widget.margin ?? const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: _onTap,
        child: TalkerBaseCard(
          color: widget.color,
          backgroundColor: widget.backgroundColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.data.title} | ${widget.data.displayTime()}',
                          style: TextStyle(
                            color: widget.color,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        if (message != null)
                          Text(
                            message,
                            maxLines: _expanded ? null : 2,
                            style: TextStyle(
                              color: widget.color,
                              fontSize: 12,
                            ),
                          ),
                        if (message == 'FlutterErrorDetails' && !_expanded)
                          Text(
                            errorMessage.toString(),
                            maxLines: 2,
                            style: TextStyle(
                              color: widget.color,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 20,
                    width: 20,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      iconSize: 20,
                      icon: Icon(
                        Icons.copy,
                        color: widget.color,
                      ),
                      onPressed: widget.onCopyTap,
                    ),
                  ),
                  if (widget.data.key?.contains('http') ?? false) ...[
                    const Gap(8),
                    SizedBox(
                      height: 20,
                      width: 20,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        iconSize: 20,
                        icon: Icon(
                          Icons.zoom_out_map_rounded,
                          color: widget.color,
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => DetailedHTTPPage(data: widget.data),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
              if (_expanded)
                Container(
                  width: double.infinity,
                  margin: stackTrace != null ? const EdgeInsets.only(top: 8) : null,
                  padding: stackTrace != null ? const EdgeInsets.all(6) : EdgeInsets.zero,
                  decoration: stackTrace != null
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
                      if (_expanded && errorType != null)
                        Text(
                          errorType,
                          style: TextStyle(
                            color: widget.color,
                            fontSize: 12,
                          ),
                        ),
                      if (_expanded && errorMessage != null)
                        Text(
                          errorMessage,
                          style: TextStyle(
                            color: widget.color,
                            fontSize: 12,
                          ),
                        ),
                      if (_expanded && riverpodFullLog != null)
                        Text(
                          riverpodFullLog,
                          style: TextStyle(
                            color: widget.color,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              if (_expanded && stackTrace != null && stackTrace.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                    border: Border.fromBorderSide(
                      BorderSide(color: widget.color),
                    ),
                  ),
                  child: Text(
                    stackTrace,
                    style: TextStyle(
                      color: widget.color,
                      fontSize: 12,
                    ),
                  ),
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
    setState(() => _expanded = !_expanded);
  }

  String? get _stackTrace {
    if ((widget.data is TalkerError ||
            widget.data is TalkerException ||
            widget.data.message == 'FlutterErrorDetails') &&
        widget.data.stackTrace != null &&
        widget.data.stackTrace.toString().isNotEmpty) {
      return 'StackTrace:\n${widget.data.stackTrace}';
    }
    return null;
  }

  String? get _message {
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

  String? get _errorMessage {
    var txt = widget.data.exception?.toString() ?? widget.data.exception?.toString();

    if ((txt?.isNotEmpty ?? false) && txt!.contains('Source stack:')) {
      txt = 'Data: ${txt.split('Source stack:').first.replaceAll('\n', '')}';
    }
    return txt;
  }

  String? get _type {
    if (widget.data is! TalkerError && widget.data is! TalkerException) {
      return null;
    }
    return 'Type: ${widget.data.exception?.runtimeType.toString() ?? widget.data.error?.runtimeType.toString() ?? ''}';
  }

  String? get _riverpodFullLog {
    final data = widget.data;

    if (data is RiverpodUpdateLog) {
      return 'Detailed: \nPREVIOUS state: ${data.previousValue} \nNEW state: ${data.newValue}';
    } else if (data is RiverpodAddLog) {
      return 'Detailed: \nINITIAL state: ${data.value}';
    } else if (data is RiverpodDisposeLog) {
      return 'Detailed: \nDISPOSED';
    } else if (data is RiverpodFailLog) {
      return 'Detailed: \nError: ${data.error} \nStackTrace: ${data.exception}';
    }

    return null;
  }
}
