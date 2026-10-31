import 'package:flutter/material.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';
import 'package:ispect/src/common/widgets/ispect_bordered_surface.dart';
import 'package:ispect/src/core/res/constants/ispect_constants.dart';

class CollapsibleSettingsSection extends StatefulWidget {
  const CollapsibleSettingsSection({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
    super.key,
  });

  final String title;
  final IconData icon;
  final Widget? trailing;
  final Widget child;

  @override
  State<CollapsibleSettingsSection> createState() =>
      _CollapsibleSettingsSectionState();
}

class _CollapsibleSettingsSectionState
    extends State<CollapsibleSettingsSection> {
  bool _expanded = false;

  void _toggle() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    final mutedColor = context.appTheme.textColor.withValues(alpha: 0.55);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            expanded: _expanded,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: kMinInteractiveDimension,
              ),
              child: ISpectBorderedSurface(
                onTap: _toggle,
                borderRadius: const BorderRadius.all(
                  Radius.circular(ISpectConstants.largeBorderRadius),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Icon(widget.icon, size: 16, color: mutedColor),
                    const Gap(10),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: context.appTheme.textTheme.labelMedium?.copyWith(
                          color: context.appTheme.textColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (widget.trailing case final trailing?) ...[
                      trailing,
                      const Gap(8),
                    ],
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: ISpectMotion.short,
                      curve: ISpectMotion.standardCurve,
                      child: Icon(
                        Icons.expand_more_rounded,
                        size: 20,
                        color: mutedColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: ISpectMotion.short,
            curve: ISpectMotion.standardCurve,
            alignment: Alignment.topCenter,
            child: _expanded
                ? Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: widget.child,
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}
