import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';
import 'package:ispect/src/features/ispect/presentation/screens/detailed_log_screen.dart';
import 'package:ispect/src/features/ispect/presentation/widgets/log_card/custom_expansion_tile.dart';

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

  final ISpectifyData data;
  final VoidCallback? onCopyTap;
  final VoidCallback? onTap;
  final bool expanded;
  final EdgeInsets? margin;
  final Color color;
  final Color backgroundColor;

  @override
  State<ISpectLogCard> createState() => _ISpectLogCardState();
}

class _ISpectLogCardState extends State<ISpectLogCard> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.expanded;
  }

  @override
  Widget build(BuildContext context) {
    final iSpect = ISpect.read(context);
    final data = widget.data;
    final stackTrace = data.stackTraceLogText;
    final errorMessage = data.errorLogText;
    final type = data.typeText;

    return ISpectExpansionTile(
      dense: true,
      initiallyExpanded: _isExpanded,
      showTrailingIcon: false,
      visualDensity: VisualDensity.compact,
      tilePadding: const EdgeInsets.symmetric(horizontal: 12),
      backgroundColor: widget.color.withValues(alpha: 0.1),
      shape: const RoundedRectangleBorder(),
      collapsedShape: const RoundedRectangleBorder(),
      childrenPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      onExpansionChanged: (value) => setState(() => _isExpanded = value),
      dividerColor: widget.color.withValues(alpha: 0.2),
      title: _CollapsedBody(
        icon: iSpect.theme.logIcons[data.key] ?? Icons.bug_report_outlined,
        color: widget.color,
        title: data.key,
        dateTime: data.formattedTime,
        onCopyTap: widget.onCopyTap,
        onHttpTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => DetailedLogScreen(data: data),
            settings: RouteSettings(
              name: 'Detailed Log Page',
              arguments: data,
            ),
          ),
        ),
        message: data.textMessage,
        errorMessage: errorMessage,
        expanded: _isExpanded,
      ),
      children: [
        if (_isExpanded)
          _ExpandedBody(
            stackTrace: stackTrace,
            widget: widget,
            expanded: _isExpanded,
            type: type,
            message: widget.data.textMessage,
            errorMessage: errorMessage,
            isHTTP: widget.data.isHttpLog,
          ),
        if (_isExpanded && stackTrace != null && stackTrace.isNotEmpty)
          _StrackTraceBody(
            widget: widget,
            stackTrace: stackTrace,
          ),
      ],
    );
  }
}
