import 'package:flutter/material.dart';
import 'package:ispect_example/circular_menu/menu.dart';

class MultiCircularMenu extends StatelessWidget {
  /// List of CircularMenu contains at least two CircularMenu objects.
  final List<CircularMenu> menus;

  /// widget holds actual page content
  final Widget? backgroundWidget;
  const MultiCircularMenu({super.key, required this.menus, this.backgroundWidget})
      : assert(menus.length != 0, 'menus can not be empty list'),
        assert(menus.length > 1, 'no need to use MultiCircularMenu you can directly use CircularMenu');
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        backgroundWidget ?? Container(),
        ...menus,
      ],
    );
  }
}
