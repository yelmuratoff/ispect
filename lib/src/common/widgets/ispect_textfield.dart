import 'package:flutter/material.dart';
import 'package:ispect/src/common/extensions/context.dart';

class ISpectTextfield extends StatelessWidget {
  const ISpectTextfield({
    required TextEditingController controller,
    this.hintText,
    super.key,
  }) : _controller = controller;

  final TextEditingController _controller;
  final String? hintText;

  @override
  Widget build(BuildContext context) => TextField(
        controller: _controller,
        onTapOutside: (_) {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.all(12),
          hintText: hintText,
          hintStyle: TextStyle(
            color: context.ispectTheme.textTheme.bodyMedium?.color
                ?.withOpacity(0.5),
            fontSize: 14,
          ),
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
      );
}
