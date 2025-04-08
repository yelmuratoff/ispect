import 'package:flutter/material.dart';
import 'package:ispectify/ispectify.dart';

/// Signature for build custom `ISpectifyError`
/// messages in showing `Snackbar` or another widgets
typedef ISpectifyErrorBuilder = Widget Function(
  BuildContext context,
  ISpectifyError data,
);

/// Signature for build custom `ISpectifyException`
/// messages in showing `Snackbar` or another widgets
typedef ISpectifyExceptionBuilder = Widget Function(
  BuildContext context,
  ISpectifyException data,
);

/// Signature for build custom `ISpectifyData` widgets
typedef ISpectifyDataBuilder = Widget Function(
  BuildContext context,
  ISpectifyData data,
);
