// ignore_for_file: avoid_positional_boolean_parameters, inference_failure_on_function_return_type, implementation_imports

import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/features/talker/presentation/widgets/base_card.dart';
import 'package:talker_flutter/src/ui/theme/default_theme.dart';

class TalkerSettingsCardItem extends StatelessWidget {
  const TalkerSettingsCardItem({
    required this.title,
    required this.enabled,
    required this.onChanged,
    super.key,
    this.canEdit = true,
    this.backgroundColor = defaultCardBackgroundColor,
  });

  final String title;
  final bool enabled;
  final Function(bool enabled) onChanged;
  final bool canEdit;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final iSpect = ISpect.read(context);
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: canEdit ? 1 : 0.7,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: ISpectBaseCard(
          padding: const EdgeInsets.symmetric(horizontal: 4).copyWith(right: 4),
          color: iSpect.theme.dividerColor(context) ??
              context.ispectTheme.dividerColor,
          backgroundColor: backgroundColor,
          child: Material(
            color: Colors.transparent,
            child: ListTile(
              dense: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              contentPadding: EdgeInsets.zero,
              title: Text(
                title,
                style: TextStyle(
                  color: context.ispectTheme.textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              trailing: Switch(
                value: enabled,
                onChanged: canEdit ? onChanged : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
