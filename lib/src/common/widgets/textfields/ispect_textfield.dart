import 'package:flutter/material.dart';
import 'package:ispect/src/common/extensions/context.dart';

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
  Widget build(BuildContext context) => TextField(
        controller: _controller,
        onTapOutside: (_) {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        minLines: minLines ?? 1,
        maxLines: maxLines,
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
            color: context.ispectTheme.textTheme.bodyMedium?.color?.withOpacity(0.5),
            fontSize: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: const BorderRadius.all(Radius.circular(8)),
            borderSide: BorderSide(
              color: context.ispectTheme.dividerColor,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: const BorderRadius.all(Radius.circular(8)),
            borderSide: BorderSide(
              color: context.ispectTheme.dividerColor,
            ),
          ),
        ),
      );
}
