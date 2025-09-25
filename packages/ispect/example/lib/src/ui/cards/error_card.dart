import 'package:flutter/material.dart';

class ErrorCard extends StatelessWidget {
  final bool enableExceptions;
  final ValueChanged<bool> onEnableExceptionsChanged;

  const ErrorCard({
    super.key,
    required this.enableExceptions,
    required this.onEnableExceptionsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _ActionGroup(
      title: 'Errors',
      icon: Icons.error,
      children: [
        CheckboxListTile(
          title: const Text('Exceptions'),
          value: enableExceptions,
          onChanged: (v) => onEnableExceptionsChanged(v ?? false),
          dense: true,
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ],
    );
  }
}

class _ActionGroup extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _ActionGroup(
      {required this.title, required this.icon, required this.children});
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Text(title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}
