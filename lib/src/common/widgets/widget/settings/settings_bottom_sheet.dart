// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member, implementation_imports

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/widgets/widget/base_bottom_sheet.dart';
import 'package:ispect/src/common/widgets/widget/settings/settings_card.dart';

import 'package:talker_flutter/talker_flutter.dart';

class TalkerSettingsBottomSheets extends StatefulWidget {
  const TalkerSettingsBottomSheets({
    required this.talker,
    required this.talkerScreenTheme,
    required this.options,
    super.key,
  });

  /// Theme for customize [TalkerScreen]
  final TalkerScreenTheme talkerScreenTheme;

  /// Talker implementation
  final ValueNotifier<Talker> talker;

  /// Options for `ISpect`
  final ISpectOptions options;

  @override
  State<TalkerSettingsBottomSheets> createState() => _TalkerSettingsBottomSheetState();
}

class _TalkerSettingsBottomSheetState extends State<TalkerSettingsBottomSheets> {
  @override
  void initState() {
    widget.talker.addListener(() => setState(() {}));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final scopedModel = ISpect.watch(context);
    final settings = <Widget>[
      TalkerSettingsCardItem(
        talkerScreenTheme: widget.talkerScreenTheme,
        title: context.ispectL10n.enabled,
        enabled: widget.talker.value.settings.enabled,
        backgroundColor: widget.talkerScreenTheme.cardColor,
        onChanged: (enabled) {
          (enabled ? widget.talker.value.enable : widget.talker.value.disable).call();
          widget.talker.notifyListeners();
        },
      ),
      TalkerSettingsCardItem(
        canEdit: widget.talker.value.settings.enabled,
        talkerScreenTheme: widget.talkerScreenTheme,
        title: context.ispectL10n.use_console_logs,
        backgroundColor: widget.talkerScreenTheme.cardColor,
        enabled: widget.talker.value.settings.useConsoleLogs,
        onChanged: (enabled) {
          widget.talker.value.configure(
            settings: widget.talker.value.settings.copyWith(
              useConsoleLogs: enabled,
            ),
          );
          widget.talker.notifyListeners();
        },
      ),
      TalkerSettingsCardItem(
        canEdit: widget.talker.value.settings.enabled,
        talkerScreenTheme: widget.talkerScreenTheme,
        title: context.ispectL10n.use_history,
        backgroundColor: widget.talkerScreenTheme.cardColor,
        enabled: widget.talker.value.settings.useHistory,
        onChanged: (enabled) {
          widget.talker.value.configure(
            settings: widget.talker.value.settings.copyWith(
              useHistory: enabled,
            ),
          );
          widget.talker.notifyListeners();
        },
      ),
      TalkerSettingsCardItem(
        talkerScreenTheme: widget.talkerScreenTheme,
        title: context.ispectL10n.performance_tracker,
        backgroundColor: widget.talkerScreenTheme.cardColor,
        enabled: scopedModel.isPerformanceTrackingEnabled,
        onChanged: (enabled) {
          scopedModel.togglePerformanceTracking();
        },
      ),
    ];

    return BaseBottomSheet(
      title: context.ispectL10n.settings,
      talkerScreenTheme: widget.talkerScreenTheme,
      child: Expanded(
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: Gap(16)),
            ...settings.map((e) => SliverToBoxAdapter(child: e)),
          ],
        ),
      ),
    );
  }
}
