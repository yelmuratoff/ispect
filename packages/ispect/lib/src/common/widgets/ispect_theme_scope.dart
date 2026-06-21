import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/core/res/ispect_theme_data.dart';

/// Injects ISpect's owned [ThemeData] above [child] so every `Theme.of` inside
/// resolves to the flat, tonal design language (dark by default).
///
/// No-ops — passes [child] through untouched — when no ISpect scope is present
/// or [ISpectTheme.useHostColors] is set, leaving the host app's theme in place.
///
/// Wrap the build output of every top-level ISpect surface (screens pushed onto
/// the in-app navigator, modal sheets/dialogs) so the injected theme reaches
/// the whole subtree. Place a `Builder` below it where the surface itself reads
/// theme tokens, so that read sits under the injected theme too.
class ISpectThemeScope extends StatelessWidget {
  const ISpectThemeScope({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final model = ISpect.maybeRead(context);
    if (model == null || model.theme.useHostColors) return child;
    return Theme(
      data: buildISpectThemeData(dark: context.ispectIsDark),
      child: child,
    );
  }
}
