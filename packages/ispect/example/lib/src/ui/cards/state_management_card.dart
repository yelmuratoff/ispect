import 'package:flutter/material.dart';

class StateManagementCard extends StatelessWidget {
  final bool enableBlocEvents;
  final bool enableRiverpod;
  final ValueChanged<bool> onEnableBlocEventsChanged;
  final ValueChanged<bool> onEnableRiverpodChanged;

  const StateManagementCard({
    super.key,
    required this.enableBlocEvents,
    required this.enableRiverpod,
    required this.onEnableBlocEventsChanged,
    required this.onEnableRiverpodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _ActionGroup(
      title: 'State Management',
      icon: Icons.memory,
      children: [
        _checkbox('Bloc Events', enableBlocEvents, onEnableBlocEventsChanged),
        _checkbox('Riverpod', enableRiverpod, onEnableRiverpodChanged),
      ],
    );
  }

  Widget _checkbox(String label, bool value, ValueChanged<bool> onChanged) {
    return CheckboxListTile(
      title: Text(label),
      value: value,
      onChanged: (v) => onChanged(v ?? false),
      dense: true,
      controlAffinity: ListTileControlAffinity.leading,
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
