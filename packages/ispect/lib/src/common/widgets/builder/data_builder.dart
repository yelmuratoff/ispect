import 'package:flutter/material.dart';
import 'package:ispectify/ispectify.dart';

/// Signature for build custom [TalkerError]
/// messages in showing [Snackbar] or another widgets
typedef TalkerErrorBuilder = Widget Function(
  BuildContext context,
  TalkerError data,
);

/// Signature for build custom [TalkerException]
/// messages in showing [Snackbar] or another widgets
typedef TalkerExceptionBuilder = Widget Function(
  BuildContext context,
  TalkerException data,
);

/// Signature for build custom [ISpectiyData] widgets
typedef TalkerDataBuilder = Widget Function(
  BuildContext context,
  ISpectiyData data,
);
