// ignore_for_file: avoid_classes_with_only_static_members, avoid_final_parameters, lines_longer_than_80_chars

import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

/// {@macro screen_util}
extension ISpectScreenUtilExtension on BuildContext {
  /// Get current screen logical size representation
  ///
  /// phone   | <= 600 dp    | 4 column
  /// tablet  | 600..1023 dp | 8 column
  /// desktop | >= 1024 dp   | 12 column
  ISpectScreenSize get screenSize => ISpectScreenUtil.screenSizeOf(this);

  /// Portrait or Landscape
  Orientation get orientation => ISpectScreenUtil.orientationOf(this);

  /// Evaluate the result of the first matching callback.
  ///
  /// phone   | <= 600 dp    | 4 column
  /// tablet  | 600..1023 dp | 8 column
  /// desktop | >= 1024 dp   | 12 column
  ScreenSizeWhenResult screenSizeWhen<ScreenSizeWhenResult extends Object?>({
    required final ScreenSizeWhenResult Function() phone,
    required final ScreenSizeWhenResult Function() tablet,
    required final ScreenSizeWhenResult Function() desktop,
  }) =>
      ISpectScreenUtil.screenSizeOf(this)
          .when(phone: phone, tablet: tablet, desktop: desktop);

  /// The [screenSizeMaybeWhen] method is equivalent to [screenSizeWhen],
  /// but doesn't require all callbacks to be specified.
  ///
  /// On the other hand, it adds an extra [orElse] required parameter,
  /// for fallback behavior.
  ScreenSizeWhenResult
      screenSizeMaybeWhen<ScreenSizeWhenResult extends Object?>({
    required final ScreenSizeWhenResult Function() orElse,
    final ScreenSizeWhenResult Function()? phone,
    final ScreenSizeWhenResult Function()? tablet,
    final ScreenSizeWhenResult Function()? desktop,
  }) =>
          ISpectScreenUtil.screenSizeOf(this).maybeWhen(
            phone: phone,
            tablet: tablet,
            desktop: desktop,
            orElse: orElse,
          );
}

/// {@template screen_util}
/// Screen logical size representation
///
/// phone   | <= 600 dp    | 4 column
/// tablet  | 600..1023 dp | 8 column
/// desktop | >= 1024 dp   | 12 column
/// {@endtemplate}
abstract final class ISpectScreenUtil {
  /// {@macro screen_util}
  static ISpectScreenSize screenSize() {
    final view = ui.PlatformDispatcher.instance.implicitView;
    if (view == null) return ISpectScreenSize.phone;
    final size = view.physicalSize ~/ view.devicePixelRatio;
    return _screenSizeFromSize(size);
  }

  static ISpectScreenSize from(Size size) => _screenSizeFromSize(size);

  /// {@macro screen_util}
  static ISpectScreenSize screenSizeOf(final BuildContext context) {
    final size = MediaQuery.of(context).size;
    return _screenSizeFromSize(size);
  }

  static ISpectScreenSize _screenSizeFromSize(final Size size) =>
      switch (size.width) {
        >= 1024 => ISpectScreenSize.desktop,
        <= 600 => ISpectScreenSize.phone,
        _ => ISpectScreenSize.tablet,
      };

  /// Portrait or Landscape
  static Orientation orientation() {
    final view = ui.PlatformDispatcher.instance.implicitView;
    final size = view?.physicalSize;
    return size == null || size.height > size.width
        ? Orientation.portrait
        : Orientation.landscape;
  }

  /// Portrait or Landscape
  static Orientation orientationOf(BuildContext context) =>
      MediaQuery.of(context).orientation;
}

/// {@macro screen_util}
@immutable
sealed class ISpectScreenSize {
  /// {@macro screen_util}
  @literal
  const ISpectScreenSize._(this.representation, this.min, this.max);

  /// Phone
  static const ISpectScreenSize phone = ISpectScreenSize$Phone();

  /// Tablet
  static const ISpectScreenSize tablet = ISpectScreenSize$Tablet();

  /// Large desktop
  static const ISpectScreenSize desktop = ISpectScreenSize$Desktop();

  /// Minimum width in logical pixels
  final double min;

  /// Maximum width in logical pixels
  final double max;

  /// String representation
  final String representation;

  /// Is phone
  abstract final bool isPhone;

  /// Is tablet
  abstract final bool isTablet;

  /// Is desktop
  abstract final bool isDesktop;

  /// Evaluate the result of the first matching callback.
  ///
  /// phone   | <= 600 dp    | 4 column
  /// tablet  | 600..1023 dp | 8 column
  /// desktop | >= 1024 dp   | 12 column
  ISpectScreenSizeWhenResult when<ISpectScreenSizeWhenResult extends Object?>({
    required final ISpectScreenSizeWhenResult Function() phone,
    required final ISpectScreenSizeWhenResult Function() tablet,
    required final ISpectScreenSizeWhenResult Function() desktop,
  });

  /// The [maybeWhen] method is equivalent to [when],
  /// but doesn't require all callbacks to be specified.
  ///
  /// On the other hand, it adds an extra [orElse] required parameter,
  /// for fallback behavior.
  ISpectScreenSizeWhenResult
      maybeWhen<ISpectScreenSizeWhenResult extends Object?>({
    required final ISpectScreenSizeWhenResult Function() orElse,
    final ISpectScreenSizeWhenResult Function()? phone,
    final ISpectScreenSizeWhenResult Function()? tablet,
    final ISpectScreenSizeWhenResult Function()? desktop,
  }) =>
          when<ISpectScreenSizeWhenResult>(
            phone: phone ?? orElse,
            tablet: tablet ?? orElse,
            desktop: desktop ?? orElse,
          );

  @override
  String toString() => representation;
}

/// {@macro screen_util}
final class ISpectScreenSize$Phone extends ISpectScreenSize {
  /// {@macro screen_util}
  @literal
  const ISpectScreenSize$Phone() : super._('Phone', 0, 599);

  @override
  ISpectScreenSizeWhenResult when<ISpectScreenSizeWhenResult extends Object?>({
    required final ISpectScreenSizeWhenResult Function() phone,
    required final ISpectScreenSizeWhenResult Function() tablet,
    required final ISpectScreenSizeWhenResult Function() desktop,
  }) =>
      phone();

  @override
  bool get isPhone => true;

  @override
  bool get isTablet => false;

  @override
  bool get isDesktop => false;

  @override
  int get hashCode => 0;

  @override
  bool operator ==(final Object other) =>
      identical(other, this) || other is ISpectScreenSize$Phone;
}

/// {@macro screen_util}
final class ISpectScreenSize$Tablet extends ISpectScreenSize {
  /// {@macro screen_util}
  @literal
  const ISpectScreenSize$Tablet() : super._('Tablet', 600, 1023);

  @override
  ISpectScreenSizeWhenResult when<ISpectScreenSizeWhenResult extends Object?>({
    required final ISpectScreenSizeWhenResult Function() phone,
    required final ISpectScreenSizeWhenResult Function() tablet,
    required final ISpectScreenSizeWhenResult Function() desktop,
  }) =>
      tablet();

  @override
  bool get isPhone => false;

  @override
  bool get isTablet => true;

  @override
  bool get isDesktop => false;

  @override
  int get hashCode => 1;

  @override
  bool operator ==(final Object other) =>
      identical(other, this) || other is ISpectScreenSize$Tablet;
}

/// {@macro screen_util}
final class ISpectScreenSize$Desktop extends ISpectScreenSize {
  /// {@macro screen_util}
  @literal
  const ISpectScreenSize$Desktop() : super._('Desktop', 1024, double.infinity);

  @override
  ScreenSizeWhenResult when<ScreenSizeWhenResult extends Object?>({
    required final ScreenSizeWhenResult Function() phone,
    required final ScreenSizeWhenResult Function() tablet,
    required final ScreenSizeWhenResult Function() desktop,
  }) =>
      desktop();

  @override
  bool get isPhone => false;

  @override
  bool get isTablet => false;

  @override
  bool get isDesktop => true;

  @override
  int get hashCode => 2;

  @override
  bool operator ==(final Object other) =>
      identical(other, this) || other is ISpectScreenSize$Desktop;
}
