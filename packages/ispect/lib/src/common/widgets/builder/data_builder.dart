import 'package:ispectify/ispectify.dart';
import 'package:material_ui/material_ui.dart';

/// Signature for build custom `ISpectLogError`
/// messages in showing `Snackbar` or another widgets
typedef ISpectLogErrorBuilder =
    Widget Function(BuildContext context, ISpectLogError data);

/// Signature for build custom `ISpectLogException`
/// messages in showing `Snackbar` or another widgets
typedef ISpectLogExceptionBuilder =
    Widget Function(BuildContext context, ISpectLogException data);

/// Signature for build custom `ISpectLogData` widgets
typedef ISpectLogDataBuilder =
    Widget Function(BuildContext context, ISpectLogData data);
