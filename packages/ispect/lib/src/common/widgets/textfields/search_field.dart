import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';

class SearchField extends StatelessWidget {
  const SearchField({
    required this.controller,
    required this.onChanged,
    super.key,
  });
  final TextEditingController? controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = context.ispectTheme;
    return TextFormField(
      controller: controller,
      style: theme.textTheme.bodyLarge!.copyWith(
        color: theme.textColor,
        fontSize: 14,
      ),
      onChanged: onChanged,
      cursorColor: context.isDarkMode
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.primary,
      onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      decoration: InputDecoration(
        fillColor: theme.cardColor,
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: context.isDarkMode
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.primary,
          ),
          borderRadius: const BorderRadius.all(Radius.circular(10)),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: ISpect.read(context).theme.dividerColor(context) ??
                theme.dividerColor,
          ),
          borderRadius: const BorderRadius.all(Radius.circular(10)),
        ),
        border: OutlineInputBorder(
          borderSide: BorderSide(
            color: ISpect.read(context).theme.dividerColor(context) ??
                theme.dividerColor,
          ),
          borderRadius: const BorderRadius.all(Radius.circular(10)),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        prefixIcon: Icon(
          Icons.search,
          color: context.isDarkMode
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.primary,
          size: 20,
        ),
        hintText: context.ispectL10n.search,
        hintStyle: theme.textTheme.bodyLarge!.copyWith(
          color: theme.hintColor,
          fontSize: 14,
        ),
      ),
    );
  }
}
