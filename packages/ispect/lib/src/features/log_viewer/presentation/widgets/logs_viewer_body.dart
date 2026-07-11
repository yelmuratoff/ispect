import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/services/log_correlation_index.dart';
import 'package:ispect/src/common/utils/screen_size.dart';
import 'package:ispect/src/common/widgets/resizable_split_view.dart';
import 'package:ispect/src/features/log_viewer/controllers/group_button.dart';
import 'package:ispect/src/features/log_viewer/controllers/ispect_view_controller.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/log_detail_view.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/main_logs_view.dart';

/// Filterable logs list plus its responsive detail panel.
///
/// The widget is agnostic to where [logsData] comes from: the live logs
/// screen feeds it a streamed history, while the session viewer feeds it an
/// independent list. All interaction is driven through [controller], so both
/// data sources behave identically.
class LogsViewerBody extends StatefulWidget {
  const LogsViewerBody({
    required this.logsData,
    required this.controller,
    required this.iSpectTheme,
    required this.titleFiltersController,
    required this.searchFocusNode,
    required this.logsScrollController,
    super.key,
    this.appBarTitle,
    this.onSettingsTap,
  });

  final List<ISpectLogData> logsData;
  final ISpectViewController controller;
  final ISpectScopeModel iSpectTheme;
  final GroupButtonController titleFiltersController;
  final FocusNode searchFocusNode;
  final ScrollController logsScrollController;
  final String? appBarTitle;
  final VoidCallback? onSettingsTap;

  @override
  State<LogsViewerBody> createState() => _LogsViewerBodyState();
}

class _LogsViewerBodyState extends State<LogsViewerBody> {
  /// Persisted split ratio so it survives detail panel toggling.
  double _splitRatio = 0.4;

  /// Correlation index for O(1) request↔response/error lookup in the
  /// detail panel. Rebuilt lazily when the input list identity changes.
  final _correlationIndex = LogCorrelationIndex();

  ISpectViewController? _lastController;
  List<ISpectLogData>? _lastLogsData;

  @override
  void initState() {
    super.initState();
    _syncDataCaches();
  }

  @override
  void didUpdateWidget(LogsViewerBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncDataCaches();
  }

  void _syncDataCaches() {
    final dataChanged = !identical(_lastController, widget.controller) ||
        !identical(_lastLogsData, widget.logsData);
    if (!dataChanged) return;

    widget.controller.onDataChanged();
    _lastController = widget.controller;
    _lastLogsData = widget.logsData;
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final isDesktop = context.screenSize.isDesktop;
    return ListenableBuilder(
      listenable: controller,
      builder: (_, __) {
        final hasDetail = isDesktop
            ? controller.detailData != null
            : controller.activeData != null;
        final showDetailPanel = hasDetail && !context.screenSize.isPhone;

        final logsView = MainLogsView(
          logsData: widget.logsData,
          iSpectTheme: widget.iSpectTheme,
          titleFiltersController: widget.titleFiltersController,
          searchFocusNode: widget.searchFocusNode,
          logsScrollController: widget.logsScrollController,
          logsViewController: controller,
          appBarTitle: widget.appBarTitle,
          onSettingsTap: widget.onSettingsTap,
          hasDetailPanel: showDetailPanel,
        );

        if (!showDetailPanel) {
          return logsView;
        }

        final activeForDetail =
            isDesktop ? controller.detailData! : controller.activeData!;

        final correlation = _findCorrelation(activeForDetail, widget.logsData);

        final detailView = LogDetailView(
          activeData: activeForDetail,
          onClose: () {
            if (isDesktop) {
              controller.closeDetail();
            } else {
              controller.activeData = null;
            }
          },
          correlatedLog: correlation?.log,
          correlationDuration: correlation?.duration,
          onNavigateToCorrelated: correlation?.log != null
              ? () {
                  if (isDesktop) {
                    controller.selectAndFollowDetail(correlation!.log!);
                  } else {
                    controller.activeData = correlation!.log;
                  }
                }
              : null,
          onShowRelated: controller.searchByCorrelationId,
        );

        if (isDesktop) {
          return ResizableSplitView(
            initialRatio: _splitRatio,
            minRatio: 0.35,
            maxRatio: 0.65,
            onRatioChanged: (ratio) => _splitRatio = ratio,
            left: logsView,
            right: detailView,
          );
        }

        // Tablet: fixed split, no drag.
        return Row(
          children: [
            Expanded(flex: 5, child: logsView),
            VerticalDivider(
              color: context.ispectTheme.divider?.resolve(context),
              width: 1,
              thickness: 1,
            ),
            Expanded(flex: 5, child: detailView),
          ],
        );
      },
    );
  }

  /// Finds a correlated log entry for the given [activeLog].
  ///
  /// Delegates to [LogCorrelationIndex] for an O(1) lookup by requestId,
  /// returning the opposite role (request → response/error, response/error
  /// → request).
  LogCorrelation? _findCorrelation(
    ISpectLogData activeLog,
    List<ISpectLogData> allLogs,
  ) =>
      _correlationIndex.find(
        activeLog,
        allLogs,
        widget.controller.outputGeneration,
      );
}
