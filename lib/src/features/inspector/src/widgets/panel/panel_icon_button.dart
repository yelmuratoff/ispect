part of 'inspector_panel.dart';

class _PanelIconButton extends StatelessWidget {
  const _PanelIconButton({
    required this.icon,
    required this.isActive,
    required this.onPressed,
  });
  final IconData icon;
  final bool isActive;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton.filled(
        icon: Icon(icon),
        splashColor: Colors.white,
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all<Color>(Colors.white),
          backgroundColor: WidgetStateProperty.all<Color>(
            isActive
                ? context.ispectTheme.colorScheme.primaryContainer
                : Colors.transparent,
          ),
          shape: WidgetStateProperty.all<RoundedRectangleBorder>(
            const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),
        ),
        onPressed: onPressed.call,
      );
}
