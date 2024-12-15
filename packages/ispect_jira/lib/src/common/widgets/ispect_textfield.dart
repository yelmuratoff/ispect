import 'package:flutter/material.dart';
import 'package:ispect_jira/src/core/localization/generated/ispect_localizations.dart';

class ISpectTextfield extends StatelessWidget {
  const ISpectTextfield({
    required TextEditingController controller,
    this.hintText,
    this.isRequired = false,
    this.minLines,
    this.maxLines,
    super.key,
  }) : _controller = controller;

  final TextEditingController _controller;
  final String? hintText;
  final bool isRequired;
  final int? minLines;
  final int? maxLines;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: TextFormField(
          controller: _controller,
          onTapOutside: (_) {
            FocusManager.instance.primaryFocus?.unfocus();
          },
          minLines: minLines ?? 1,
          maxLines: maxLines,
          validator: (value) {
            if (isRequired && value!.isEmpty) {
              return ISpectJiraLocalization.of(context)!.fieldIsRequired;
            }
            return null;
          },
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.all(12),
            hintText: hintText,
            alignLabelWithHint: true,
            labelText: isRequired ? null : hintText,
            label: isRequired
                ? Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: hintText,
                        ),
                        const TextSpan(
                          text: ' *',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : null,
            hintStyle: TextStyle(
              color: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.color
                  ?.withValues(alpha: 0.5),
              fontSize: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              borderSide: BorderSide(
                color: Theme.of(context).dividerColor,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              borderSide: BorderSide(
                color: Theme.of(context).dividerColor,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              borderSide: BorderSide(
                color: Theme.of(context).dividerColor,
              ),
            ),
          ),
        ),
      );
}
