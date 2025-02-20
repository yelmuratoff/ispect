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
    _stackTrace = widget.data.stackTraceLogText;

    _errorMessage = widget.data.errorLogText;
    _type = widget.data.typeText;
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
                icon: iSpect.theme.logIcons[widget.data.key] ?? Icons.bug_report_outlined,
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
                isHttpLog: widget.data.isHttpLog,
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
                  isHTTP: widget.data.isHttpLog,
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
}
