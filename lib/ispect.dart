library ispect;

import 'package:flutter/material.dart';
import 'package:ispect/src/common/controllers/ispect_scope.dart';
import 'package:provider/provider.dart';

export 'package:ispect/src/common/controllers/ispect_scope.dart';
export 'package:ispect/src/common/services/talker/talker_wrapper.dart';
export 'package:ispect/src/common/utils/ispect_localizations.dart';
export 'package:ispect/src/common/utils/ispect_options.dart';
export 'package:ispect/src/common/widgets/builder/inspector_builder.dart';
export 'package:ispect/src/common/widgets/draggable_button.dart';
export 'package:ispect/src/core/localization/localization.dart';

final class ISpect {
  static ISpectScopeModel read(BuildContext context) =>
      Provider.of<ISpectScopeModel>(context, listen: false);

  static ISpectScopeModel watch(BuildContext context) =>
      Provider.of<ISpectScopeModel>(context);
}
