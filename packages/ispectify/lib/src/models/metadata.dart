import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

/// Environment/runtime metadata attached to exported log files.
///
/// ISpect never collects these values itself — doing so would require
/// platform plugins (`package_info_plus`, `device_info_plus`) and break web
/// builds. Instead the host app supplies them, since it already owns those
/// sources (or build-time `--dart-define` constants). All fields are optional;
/// [toMap] omits the `null` ones.
///
/// Keep tokens, credentials, and PII out of these fields — the metadata block
/// is written verbatim into shared/exported files and is not redacted.
@immutable
final class ISpectMetadata {
  const ISpectMetadata({
    this.appName,
    this.appVersion,
    this.buildNumber,
    this.environment,
    this.device,
    this.os,
    this.osVersion,
    this.locale,
    this.extra,
  });

  /// JSON key under which this metadata block is written in exported logs.
  static const String exportKey = 'metadata';

  /// Human-readable application name (e.g. `My App`).
  final String? appName;

  /// Marketing/semantic app version (e.g. `1.4.2`).
  final String? appVersion;

  /// Build/version code (e.g. `142`).
  final String? buildNumber;

  /// Deployment environment (e.g. `production`, `staging`, `dev`).
  final String? environment;

  /// Device model or identifier (e.g. `iPhone 15 Pro`, `Pixel 8`).
  final String? device;

  /// Operating system name (e.g. `iOS`, `Android`, `web`).
  final String? os;

  /// Operating system version (e.g. `17.4`).
  final String? osVersion;

  /// Active locale (e.g. `en_US`).
  final String? locale;

  /// Additional free-form entries for values without a dedicated field.
  ///
  /// Typed fields take precedence over [extra] keys with the same name.
  final Map<String, Object?>? extra;

  /// Returns the metadata as a map, dropping `null`-valued typed fields.
  ///
  /// [extra] is merged first so the typed fields win on key collision.
  Map<String, Object?> toMap() => {
        ...?extra,
        if (appName != null) 'appName': appName,
        if (appVersion != null) 'appVersion': appVersion,
        if (buildNumber != null) 'buildNumber': buildNumber,
        if (environment != null) 'environment': environment,
        if (device != null) 'device': device,
        if (os != null) 'os': os,
        if (osVersion != null) 'osVersion': osVersion,
        if (locale != null) 'locale': locale,
      };

  /// Whether every field is unset, so [toMap] would return an empty map.
  bool get isEmpty => toMap().isEmpty;

  ISpectMetadata copyWith({
    String? appName,
    String? appVersion,
    String? buildNumber,
    String? environment,
    String? device,
    String? os,
    String? osVersion,
    String? locale,
    Map<String, Object?>? extra,
  }) =>
      ISpectMetadata(
        appName: appName ?? this.appName,
        appVersion: appVersion ?? this.appVersion,
        buildNumber: buildNumber ?? this.buildNumber,
        environment: environment ?? this.environment,
        device: device ?? this.device,
        os: os ?? this.os,
        osVersion: osVersion ?? this.osVersion,
        locale: locale ?? this.locale,
        extra: extra ?? this.extra,
      );

  static const _equality = DeepCollectionEquality();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ISpectMetadata &&
          other.appName == appName &&
          other.appVersion == appVersion &&
          other.buildNumber == buildNumber &&
          other.environment == environment &&
          other.device == device &&
          other.os == os &&
          other.osVersion == osVersion &&
          other.locale == locale &&
          _equality.equals(other.extra, extra);

  @override
  int get hashCode => Object.hash(
        appName,
        appVersion,
        buildNumber,
        environment,
        device,
        os,
        osVersion,
        locale,
        _equality.hash(extra),
      );

  @override
  String toString() => 'ISpectMetadata(${toMap()})';
}
