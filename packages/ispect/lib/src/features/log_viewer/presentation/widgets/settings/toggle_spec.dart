import 'package:material_ui/material_ui.dart';

class ToggleSpec {
  const ToggleSpec({
    required this.title,
    required this.icon,
    required this.enabled,
    required this.onChanged,
    this.canEdit = true,
  });

  final String title;
  final IconData icon;
  final bool enabled;
  final bool canEdit;
  final ValueChanged<bool> onChanged;
}
