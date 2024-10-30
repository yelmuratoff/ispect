// ignore_for_file: implementation_imports

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/features/talker/presentation/pages/detailed_info/monitor_info_page.dart';
import 'package:ispect/src/features/talker/presentation/widgets/base_card.dart';
import 'package:talker_flutter/talker_flutter.dart';

part '../../widgets/monitor_card.dart';

class TalkerMonitorPage extends StatefulWidget {
  const TalkerMonitorPage({
    required this.options,
    super.key,
  });

  final ISpectOptions options;

  @override
  State<TalkerMonitorPage> createState() => _TalkerMonitorPageState();
}

class _TalkerMonitorPageState extends State<TalkerMonitorPage> {
  @override
  Widget build(BuildContext context) {
    final iSpect = ISpect.read(context);
    return Scaffold(
      backgroundColor: iSpect.theme.backgroundColor(context),
      appBar: AppBar(
        backgroundColor: iSpect.theme.backgroundColor(context),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'ISpect monitor',
            style: context.ispectTheme.textTheme.titleMedium,
          ),
        ),
      ),
      body: TalkerBuilder(
        talker: ISpect.talker,
        builder: (context, data) {
          // <-- Common logs -->

          final logs = data.whereType<TalkerLog>().toList();
          final errors = data.whereType<TalkerError>().toList();
          final exceptions = data.whereType<TalkerException>().toList();
          final flutterErrors = data.where((e) => e.message == 'FlutterErrorDetails').toList();
          final warnings = logs.where((e) => e.logLevel == LogLevel.warning).toList();
          final goods = logs.where((e) => e.title == 'good').toList();
          final prints = logs.where((e) => e.title == 'print').toList();

          final infos = logs.where((e) => e.logLevel == LogLevel.info).toList();
          final verboseDebug = logs
              .where(
                (e) => e.logLevel == LogLevel.verbose || e.logLevel == LogLevel.debug,
              )
              .toList();

          // <-- HTTP logs -->

          final httpRequests = data.where((e) => e.key == TalkerLogType.httpRequest.key).toList();
          final httpErrors = data.where((e) => e.key == TalkerLogType.httpError.key).toList();
          final httpResponses = data.where((e) => e.key == TalkerLogType.httpResponse.key).toList();
          final allHttps = data
              .where(
                (e) =>
                    e.key == TalkerLogType.httpRequest.key ||
                    e.key == TalkerLogType.httpError.key ||
                    e.key == TalkerLogType.httpResponse.key,
              )
              .toList();

          // <-- BLoC logs -->

          final blocEvents = data.where((e) => e.key == TalkerLogType.blocEvent.key).toList();
          final blocTransitions = data.where((e) => e.key == TalkerLogType.blocTransition.key).toList();
          final blocCreates = data.where((e) => e.key == TalkerLogType.blocCreate.key).toList();
          final blocCloses = data.where((e) => e.key == TalkerLogType.blocClose.key).toList();
          final allBlocs = data
              .where(
                (e) =>
                    e.key == TalkerLogType.blocEvent.key ||
                    e.key == TalkerLogType.blocTransition.key ||
                    e.key == TalkerLogType.blocCreate.key ||
                    e.key == TalkerLogType.blocClose.key,
              )
              .toList();

          // <-- Riverpod logs -->

          final allRiverpod = data
              .where(
                (e) =>
                    e.key == TalkerLogType.riverpodAdd.key ||
                    e.key == TalkerLogType.riverpodUpdate.key ||
                    e.key == TalkerLogType.riverpodDispose.key ||
                    e.key == TalkerLogType.riverpodFail.key,
              )
              .toList();
          final riverpodAdds = data.where((e) => e.key == TalkerLogType.riverpodAdd.key).toList();
          final riverpodUpdates = data.where((e) => e.key == TalkerLogType.riverpodUpdate.key).toList();
          final riverpodDisposes = data.where((e) => e.key == TalkerLogType.riverpodDispose.key).toList();
          final riverpodFails = data.where((e) => e.key == TalkerLogType.riverpodFail.key).toList();

          return CustomScrollView(
            slivers: [
              if (httpRequests.isNotEmpty) ...[
                const SliverToBoxAdapter(child: Gap(10)),
                SliverToBoxAdapter(
                  child: _TalkerMonitorsCard(
                    logs: httpRequests,
                    title: context.ispectL10n.talkerTypeHttp,
                    color: Colors.green,
                    icon: Icons.http_rounded,
                    onTap: () => _openTypedLogsScreen(
                      context,
                      allHttps,
                      context.ispectL10n.talkerTypeHttp,
                    ),
                    subtitleWidget: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.ispectL10n.talkerHttpRequestsCount(
                            httpRequests.length,
                          ),
                          style: TextStyle(
                            color: iSpect.theme.getTypeColor(
                              context,
                              key: 'http-request',
                            ),
                          ),
                        ),
                        Text(
                          context.ispectL10n.talkerHttpFailuresCount(
                            httpErrors.length,
                          ),
                          style: TextStyle(
                            color: iSpect.theme.getTypeColor(
                              context,
                              key: 'http-error',
                            ),
                          ),
                        ),
                        Text(
                          context.ispectL10n.talkerHttpResponsesCount(
                            httpResponses.length,
                          ),
                          style: TextStyle(
                            color: iSpect.theme.getTypeColor(
                              context,
                              key: 'http-response',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (allBlocs.isNotEmpty) ...[
                const SliverToBoxAdapter(child: Gap(10)),
                SliverToBoxAdapter(
                  child: _TalkerMonitorsCard(
                    logs: allBlocs,
                    title: context.ispectL10n.talkerTypeBloc,
                    color: Colors.grey,
                    icon: Icons.code_rounded,
                    onTap: () => _openTypedLogsScreen(
                      context,
                      allBlocs,
                      context.ispectL10n.talkerTypeBloc,
                    ),
                    subtitleWidget: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.ispectL10n.talkerBlocEventsCount(
                            blocEvents.length,
                          ),
                          style: TextStyle(
                            color: iSpect.theme.getTypeColor(
                              context,
                              key: 'bloc-event',
                            ),
                          ),
                        ),
                        Text(
                          context.ispectL10n.talkerBlocTransitionCount(
                            blocTransitions.length,
                          ),
                          style: TextStyle(
                            color: iSpect.theme.getTypeColor(
                              context,
                              key: 'bloc-transition',
                            ),
                          ),
                        ),
                        Text(
                          context.ispectL10n.talkerBlocCreatesCount(
                            blocCreates.length,
                          ),
                          style: TextStyle(
                            color: iSpect.theme.getTypeColor(
                              context,
                              key: 'bloc-create',
                            ),
                          ),
                        ),
                        Text(
                          context.ispectL10n.talkerBlocClosesCount(
                            blocCloses.length,
                          ),
                          style: TextStyle(
                            color: iSpect.theme.getTypeColor(
                              context,
                              key: 'bloc-close',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (allRiverpod.isNotEmpty) ...[
                const SliverToBoxAdapter(child: Gap(10)),
                SliverToBoxAdapter(
                  child: _TalkerMonitorsCard(
                    logs: allRiverpod,
                    title: context.ispectL10n.talkerTypeRiverpod,
                    color: Colors.grey,
                    icon: Icons.code_rounded,
                    onTap: () => _openTypedLogsScreen(
                      context,
                      allRiverpod,
                      context.ispectL10n.talkerTypeRiverpod,
                    ),
                    subtitleWidget: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.ispectL10n.talkerRiverpodAddCount(
                            riverpodAdds.length,
                          ),
                          style: TextStyle(
                            color: iSpect.theme.getTypeColor(
                              context,
                              key: 'riverpod-add',
                            ),
                          ),
                        ),
                        Text(
                          context.ispectL10n.talkerRiverpodUpdateCount(
                            riverpodUpdates.length,
                          ),
                          style: TextStyle(
                            color: iSpect.theme.getTypeColor(
                              context,
                              key: 'riverpod-update',
                            ),
                          ),
                        ),
                        Text(
                          context.ispectL10n.talkerRiverpodDisposeCount(
                            riverpodDisposes.length,
                          ),
                          style: TextStyle(
                            color: iSpect.theme.getTypeColor(
                              context,
                              key: 'riverpod-dispose',
                            ),
                          ),
                        ),
                        Text(
                          context.ispectL10n.talkerRiverpodFailsCount(
                            riverpodFails.length,
                          ),
                          style: TextStyle(
                            color: iSpect.theme.getTypeColor(
                              context,
                              key: 'riverpod-fail',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (errors.isNotEmpty) ...[
                const SliverToBoxAdapter(child: Gap(10)),
                SliverToBoxAdapter(
                  child: _TalkerMonitorsCard(
                    logs: errors,
                    title: context.ispectL10n.talkerTypeErrors,
                    color: iSpect.theme.getTypeColor(
                      context,
                      key: 'error',
                    ),
                    icon: Icons.error_outline_rounded,
                    subtitle: context.ispectL10n.talkerTypeErrorsCount(errors.length),
                    onTap: () => _openTypedLogsScreen(
                      context,
                      errors,
                      context.ispectL10n.talkerTypeErrors,
                    ),
                  ),
                ),
              ],
              if (flutterErrors.isNotEmpty) ...[
                const SliverToBoxAdapter(child: Gap(10)),
                SliverToBoxAdapter(
                  child: _TalkerMonitorsCard(
                    logs: flutterErrors,
                    title: '${context.ispectL10n.talkerTypeErrors} (flutter)',
                    color: iSpect.theme.getTypeColor(
                      context,
                      key: 'error',
                    ),
                    icon: Icons.error_outline_rounded,
                    subtitle: context.ispectL10n.talkerTypeErrorsCount(flutterErrors.length),
                    onTap: () => _openTypedLogsScreen(
                      context,
                      flutterErrors,
                      '${context.ispectL10n.talkerTypeErrors} (flutter)',
                    ),
                  ),
                ),
              ],
              if (exceptions.isNotEmpty) ...[
                const SliverToBoxAdapter(child: Gap(10)),
                SliverToBoxAdapter(
                  child: _TalkerMonitorsCard(
                    logs: exceptions,
                    title: context.ispectL10n.talkerTypeExceptions,
                    color: iSpect.theme.getTypeColor(
                      context,
                      key: 'exception',
                    ),
                    icon: Icons.error_outline_rounded,
                    subtitle: context.ispectL10n.talkerTypeExceptionsCount(exceptions.length),
                    onTap: () => _openTypedLogsScreen(
                      context,
                      exceptions,
                      context.ispectL10n.talkerTypeExceptions,
                    ),
                  ),
                ),
              ],
              if (warnings.isNotEmpty) ...[
                const SliverToBoxAdapter(child: Gap(10)),
                SliverToBoxAdapter(
                  child: _TalkerMonitorsCard(
                    logs: warnings,
                    title: context.ispectL10n.talkerTypeWarnings,
                    color: iSpect.theme.getTypeColor(
                      context,
                      key: 'warning',
                    ),
                    icon: Icons.warning_amber_rounded,
                    subtitle: context.ispectL10n.talkerTypeWarningsCount(warnings.length),
                    onTap: () => _openTypedLogsScreen(
                      context,
                      warnings,
                      context.ispectL10n.talkerTypeWarnings,
                    ),
                  ),
                ),
              ],
              if (infos.isNotEmpty) ...[
                const SliverToBoxAdapter(child: Gap(10)),
                SliverToBoxAdapter(
                  child: _TalkerMonitorsCard(
                    logs: infos,
                    title: context.ispectL10n.talkerTypeInfo,
                    color: iSpect.theme.getTypeColor(
                      context,
                      key: 'info',
                    ),
                    icon: Icons.info_outline_rounded,
                    subtitle: context.ispectL10n.talkerTypeInfoCount(infos.length),
                    onTap: () => _openTypedLogsScreen(
                      context,
                      infos,
                      context.ispectL10n.talkerTypeInfo,
                    ),
                  ),
                ),
              ],
              if (goods.isNotEmpty) ...[
                const SliverToBoxAdapter(child: Gap(10)),
                SliverToBoxAdapter(
                  child: _TalkerMonitorsCard(
                    logs: goods,
                    title: context.ispectL10n.talkerTypeGood,
                    color: iSpect.theme.getTypeColor(
                      context,
                      key: 'good',
                    ),
                    icon: Icons.check_circle_outline_rounded,
                    subtitle: context.ispectL10n.talkerTypeGoodCount(goods.length),
                    onTap: () => _openTypedLogsScreen(
                      context,
                      goods,
                      context.ispectL10n.talkerTypeGood,
                    ),
                  ),
                ),
              ],
              if (prints.isNotEmpty) ...[
                const SliverToBoxAdapter(child: Gap(10)),
                SliverToBoxAdapter(
                  child: _TalkerMonitorsCard(
                    logs: prints,
                    title: context.ispectL10n.talkerTypePrint,
                    color: iSpect.theme.getTypeColor(
                      context,
                      key: 'print',
                    ),
                    icon: Icons.check_circle_outline_rounded,
                    subtitle: context.ispectL10n.talkerTypePrintCount(prints.length),
                    onTap: () => _openTypedLogsScreen(
                      context,
                      prints,
                      context.ispectL10n.talkerTypePrint,
                    ),
                  ),
                ),
              ],
              if (verboseDebug.isNotEmpty) ...[
                const SliverToBoxAdapter(child: Gap(10)),
                SliverToBoxAdapter(
                  child: _TalkerMonitorsCard(
                    logs: verboseDebug,
                    title: context.ispectL10n.talkerTypeDebug,
                    color: iSpect.theme.getTypeColor(
                      context,
                      key: 'verbose',
                    ),
                    icon: Icons.remove_red_eye_outlined,
                    subtitle: context.ispectL10n.talkerTypeDebugCount(verboseDebug.length),
                    onTap: () => _openTypedLogsScreen(
                      context,
                      verboseDebug,
                      context.ispectL10n.talkerTypeDebug,
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  void _openTypedLogsScreen(
    BuildContext context,
    List<TalkerData> logs,
    String typeName,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<Widget>(
        builder: (_) => MonitorPage(
          data: logs,
          typeName: typeName,
          options: widget.options,
        ),
        settings: RouteSettings(
          name: 'MonitorPage',
          arguments: typeName,
        ),
      ),
    );
  }
}
