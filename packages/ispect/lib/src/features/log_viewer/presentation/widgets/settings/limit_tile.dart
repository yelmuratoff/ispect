import 'package:flutter/material.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';

String formatCount(int value) {
  if (value >= 1000 && value % 1000 == 0) return '${value ~/ 1000}k';
  return value.toString();
}

class LimitTile extends StatelessWidget {
  const LimitTile({
    required this.label,
    required this.description,
    required this.icon,
    required this.value,
    required this.options,
    required this.formatter,
    required this.onChanged,
    super.key,
  });

  final String label;
  final String description;
  final IconData icon;
  final int value;
  final List<int> options;
  final String Function(int value) formatter;
  final ValueChanged<int> onChanged;

  Future<void> _openEditor(BuildContext context) async {
    final result = await showDialog<int>(
      context: context,
      builder: (_) => _LimitEditorDialog(
        label: label,
        description: description,
        icon: icon,
        value: value,
        presets: options,
        formatter: formatter,
      ),
    );
    if (result != null && result != value) onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = context.ispectTheme.card?.resolve(context) ??
        context.appTheme.cardColor;
    final primaryColor = context.ispectTheme.primary?.resolve(context) ??
        context.appTheme.colorScheme.primary;
    final textColor = context.appTheme.textColor;

    return Material(
      color: cardColor,
      borderRadius: const BorderRadius.all(Radius.circular(10)),
      child: InkWell(
        onTap: () => _openEditor(context),
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(
              color: context.appTheme.colorScheme.onSurface.withValues(
                alpha: 0.08,
              ),
            ),
            borderRadius: const BorderRadius.all(Radius.circular(10)),
          ),
          child: Padding(
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    border: Border.all(
                      color: primaryColor.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formatter(value),
                        style: context.appTheme.textTheme.labelMedium?.copyWith(
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Gap(4),
                      Icon(
                        Icons.edit_rounded,
                        size: 14,
                        color: primaryColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LimitEditorDialog extends StatefulWidget {
  const _LimitEditorDialog({
    required this.label,
    required this.description,
    required this.icon,
    required this.value,
    required this.presets,
    required this.formatter,
  });

  final String label;
  final String description;
  final IconData icon;
  final int value;
  final List<int> presets;
  final String Function(int value) formatter;

  @override
  State<_LimitEditorDialog> createState() => _LimitEditorDialogState();
}

class _LimitEditorDialogState extends State<_LimitEditorDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.value.toString());
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _selectPreset(int preset) {
    _controller.text = preset.toString();
    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );
    setState(() => _error = null);
  }

  void _submit() {
    final raw = _controller.text.trim();
    final parsed = int.tryParse(raw);
    if (parsed == null || parsed < 0) {
      setState(() => _error = 'Enter a non-negative integer');
      return;
    }
    Navigator.of(context).pop(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = context.ispectTheme.primary?.resolve(context) ??
        context.appTheme.colorScheme.primary;
    final bgColor = context.ispectTheme.background?.resolve(context) ??
        context.appTheme.colorScheme.surfaceContainerLowest;
    final fieldColor = context.ispectTheme.card?.resolve(context) ??
        context.appTheme.colorScheme.surfaceContainerHigh;
    final textColor = context.appTheme.textColor;
    final onSurface = context.appTheme.colorScheme.onSurface;
    final borderColor = onSurface.withValues(alpha: 0.08);

    return AlertDialog(
      backgroundColor: bgColor,
      surfaceTintColor: Colors.transparent,
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 12, 8),
      contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      title: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.12),
              borderRadius: const BorderRadius.all(Radius.circular(10)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(widget.icon, color: primaryColor, size: 22),
            ),
          ),
          const Gap(12),
          Expanded(
            child: Text(
              widget.label,
              style: context.appTheme.textTheme.titleLarge?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.description,
            style: context.appTheme.textTheme.bodySmall?.copyWith(
              color: textColor.withValues(alpha: 0.55),
            ),
          ),
          const Gap(12),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            onSubmitted: (_) => _submit(),
            style: TextStyle(
              fontSize: 14,
              color: onSurface,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: fieldColor,
              hintText: '0 disables this limit',
              hintStyle: TextStyle(
                fontSize: 14,
                color: onSurface.withValues(alpha: 0.5),
              ),
              errorText: _error,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: const BorderRadius.all(Radius.circular(10)),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: const BorderRadius.all(Radius.circular(10)),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: const BorderRadius.all(Radius.circular(10)),
                borderSide: BorderSide(color: primaryColor, width: 1.2),
              ),
            ),
          ),
          const Gap(12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final preset in widget.presets)
                _PresetChip(
                  label: widget.formatter(preset),
                  selected: preset == int.tryParse(_controller.text.trim()),
                  onTap: () => _selectPreset(preset),
                ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primaryColor = context.ispectTheme.primary?.resolve(context) ??
        context.appTheme.colorScheme.primary;
    final cardColor = context.ispectTheme.card?.resolve(context) ??
        context.appTheme.colorScheme.surfaceContainerHigh;
    final onSurface = context.appTheme.colorScheme.onSurface;

    final bg = selected ? primaryColor.withValues(alpha: 0.12) : cardColor;
    final border = selected
        ? primaryColor.withValues(alpha: 0.35)
        : onSurface.withValues(alpha: 0.08);
    final fg = selected ? primaryColor : context.appTheme.textColor;

    return Material(
      color: bg,
      borderRadius: const BorderRadius.all(Radius.circular(10)),
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: border),
            borderRadius: const BorderRadius.all(Radius.circular(10)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(
              label,
              style: context.appTheme.textTheme.labelMedium?.copyWith(
                color: fg,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
