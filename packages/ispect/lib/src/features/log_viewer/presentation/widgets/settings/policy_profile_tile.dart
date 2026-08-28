import 'package:flutter/material.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/utils/squircle.dart';
import 'package:ispect/src/common/widgets/bottom_sheet_header.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';
import 'package:ispect/src/common/widgets/ispect_alert_dialog.dart';
import 'package:ispect/src/common/widgets/ispect_bordered_surface.dart';
import 'package:ispect/src/core/res/constants/ispect_constants.dart';

@immutable
final class PolicyProfileOption<T> {
  const PolicyProfileOption({
    required this.label,
    required this.description,
    required this.value,
  });

  final String label;
  final String description;
  final T value;
}

class PolicyProfileTile<T> extends StatelessWidget {
  const PolicyProfileTile({
    required this.label,
    required this.description,
    required this.icon,
    required this.value,
    required this.options,
    required this.onChanged,
    super.key,
  });

  final String label;
  final String description;
  final IconData icon;
  final T value;
  final List<PolicyProfileOption<T>> options;
  final ValueChanged<T> onChanged;

  PolicyProfileOption<T>? get _selectedOption {
    for (final option in options) {
      if (option.value == value) return option;
    }
    return null;
  }

  Future<void> _openSelector(BuildContext context) async {
    final result = await showDialog<T>(
      context: context,
      builder: (_) => _PolicyProfileDialog<T>(
        label: label,
        description: description,
        icon: icon,
        value: value,
        options: options,
      ),
    );
    if (result != null && result != value) onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = context.ispectPrimaryColor;
    final textColor = context.appTheme.textColor;

    return ISpectBorderedSurface(
      onTap: () => _openSelector(context),
      semanticsLabel: label,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: primaryColor),
          ),
          const Gap(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: context.appTheme.textTheme.labelLarge?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: context.appTheme.textTheme.bodySmall?.copyWith(
                    color: textColor.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: ISpectSquircle.decoration(
              color: primaryColor.withValues(alpha: 0.1),
              radius: ISpectConstants.standardBorderRadius,
              side: BorderSide(color: primaryColor.withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _selectedOption?.label ?? 'Custom',
                  style: context.appTheme.textTheme.labelMedium?.copyWith(
                    color: primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Gap(4),
                Icon(Icons.tune_rounded, size: 14, color: primaryColor),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicyProfileDialog<T> extends StatelessWidget {
  const _PolicyProfileDialog({
    required this.label,
    required this.description,
    required this.icon,
    required this.value,
    required this.options,
  });

  final String label;
  final String description;
  final IconData icon;
  final T value;
  final List<PolicyProfileOption<T>> options;

  @override
  Widget build(BuildContext context) => ISpectAlertDialog(
    titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
    contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
    title: ISpectDialogHeader(title: label, subtitle: description, icon: icon),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < options.length; index++) ...[
          _PolicyProfileOptionTile<T>(
            option: options[index],
            selected: options[index].value == value,
          ),
          if (index < options.length - 1) const Gap(8),
        ],
      ],
    ),
  );
}

class _PolicyProfileOptionTile<T> extends StatelessWidget {
  const _PolicyProfileOptionTile({
    required this.option,
    required this.selected,
  });

  final PolicyProfileOption<T> option;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final primaryColor = context.ispectPrimaryColor;
    final textColor = context.appTheme.textColor;
    return ISpectBorderedSurface(
      onTap: () => Navigator.of(context).pop(option.value),
      semanticsLabel: option.label,
      backgroundColor: selected ? primaryColor.withValues(alpha: 0.12) : null,
      borderColor: selected ? primaryColor.withValues(alpha: 0.35) : null,
      child: Row(
        children: [
          Icon(
            selected
                ? Icons.radio_button_checked_rounded
                : Icons.radio_button_unchecked_rounded,
            color: selected ? primaryColor : textColor.withValues(alpha: 0.45),
            size: 18,
          ),
          const Gap(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  option.label,
                  style: context.appTheme.textTheme.labelLarge?.copyWith(
                    color: selected ? primaryColor : textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  option.description,
                  style: context.appTheme.textTheme.bodySmall?.copyWith(
                    color: textColor.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
