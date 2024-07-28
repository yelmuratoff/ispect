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
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: InkWell(
            onTap: onPressed,
            borderRadius: const BorderRadius.all(Radius.circular(16)),
            child: Ink(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isActive
                    ? context.ispectTheme.colorScheme.primaryContainer
                    : adjustColorDarken(
                        context.ispectTheme.colorScheme.primaryContainer,
                        0.3,
                      ),
                borderRadius: const BorderRadius.all(Radius.circular(16)),
              ),
              child: Icon(
                icon,
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
  // Material(
  //       color: Colors.transparent,
  //       child: IconButton.filled(
  //         icon: Icon(icon),
  //         style: ButtonStyle(
  //           foregroundColor: WidgetStateProperty.all<Color>(Colors.white),
  //           backgroundColor: WidgetStateProperty.all<Color>(
  //             isActive
  //                 ? context.ispectTheme.colorScheme.primaryContainer
  //                 : adjustColorDarken(
  //                     context.ispectTheme.colorScheme.primaryContainer,
  //                     0.3,
  //                   ),
  //           ),
  //           shape: WidgetStateProperty.all<RoundedRectangleBorder>(
  //             const RoundedRectangleBorder(
  //               borderRadius: BorderRadius.all(Radius.circular(16)),
  //             ),
  //           ),
  //         ),
  //         onPressed: onPressed.call,
  //       ),
  //     );
}
