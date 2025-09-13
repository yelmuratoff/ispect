import 'package:flutter/material.dart';

class LoggingCard extends StatelessWidget {
  final bool enableLogging;
  final bool enableAnalytics;
  final bool enableRoutes;
  final ValueChanged<bool> onEnableLoggingChanged;
  final ValueChanged<bool> onEnableAnalyticsChanged;
  final ValueChanged<bool> onEnableRoutesChanged;

  const LoggingCard({
    super.key,
    required this.enableLogging,
    required this.enableAnalytics,
    required this.enableRoutes,
    required this.onEnableLoggingChanged,
    required this.onEnableAnalyticsChanged,
    required this.onEnableRoutesChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _ActionGroup(
      title: 'Logging',
      icon: Icons.bug_report,
      children: [
        _checkbox('All Log Types', enableLogging, onEnableLoggingChanged),
        _checkbox('Analytics', enableAnalytics, onEnableAnalyticsChanged),
        _checkbox('Routes', enableRoutes, onEnableRoutesChanged),
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
