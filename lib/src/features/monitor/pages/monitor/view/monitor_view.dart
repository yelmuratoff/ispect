part of '../talker_monitor_page.dart';

class _MonitorView extends StatelessWidget {
  final TalkerScreenTheme theme;
  final ISpectOptions options;
  final Function(List<TalkerData>, String) openTypedLogsPage;

  const _MonitorView({
    required this.theme,
    required this.options,
    required this.openTypedLogsPage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
        talker: options.talker,
        builder: (context, data) {
          final logs = data.whereType<TalkerLog>().toList();
          final errors = data.whereType<TalkerError>().toList();
          final exceptions = data.whereType<TalkerException>().toList();
          final warnings = logs.where((e) => e.logLevel == LogLevel.warning).toList();
          final goods = logs.where((e) => e.title == "good").toList();

          final infos = logs.where((e) => e.logLevel == LogLevel.info).toList();
          final verboseDebug = logs
              .where(
                (e) => e.logLevel == LogLevel.verbose || e.logLevel == LogLevel.debug,
              )
              .toList();

          final httpRequests = data.where((e) => e.key == TalkerLogType.httpRequest.key).toList();
          final httpErrors = data.where((e) => e.key == TalkerLogType.httpError.key).toList();
          final httpResponses = data.where((e) => e.key == TalkerLogType.httpResponse.key).toList();
          final allHttps = data
              .where(
                (e) => e.key == TalkerLogType.httpRequest.key || e.key == TalkerLogType.httpError.key || e.key == TalkerLogType.httpResponse.key,
              )
              .toList();
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

          final providers = logs.where((e) => e.title == "provider").toList();

          return CustomScrollView(
            slivers: [
              if (httpRequests.isNotEmpty) ...[
                const SliverToBoxAdapter(child: SizedBox(height: 10)),
                SliverToBoxAdapter(
                  child: _TalkerMonitorsCard(
                    logs: httpRequests,
                    title: context.ispectL10n.talker_type_http,
                    color: Colors.green,
                    icon: Icons.http_rounded,
                    onTap: () => openTypedLogsPage(
                      allHttps,
                      context.ispectL10n.talker_type_http,
                    ),
                    subtitleWidget: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.ispectL10n.talker_http_requests_count(
                            httpRequests.length,
                          ),
                          style: const TextStyle(
                            color: Color(0xFFF602C1),
                          ),
                        ),
                        Text(
                          context.ispectL10n.talker_http_failues_count(
                            httpErrors.length,
                          ),
                          style: const TextStyle(
                            color: Color.fromARGB(255, 239, 83, 80),
                          ),
                        ),
                        Text(
                          context.ispectL10n.talker_http_responses_count(
                            httpResponses.length,
                          ),
                          style: const TextStyle(
                            color: Color(0xFF26FF3C),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (allBlocs.isNotEmpty) ...[
                const SliverToBoxAdapter(child: SizedBox(height: 10)),
                SliverToBoxAdapter(
                  child: _TalkerMonitorsCard(
                    logs: allBlocs,
                    title: context.ispectL10n.talker_type_bloc,
                    color: Colors.grey,
                    icon: Icons.code_rounded,
                    onTap: () => openTypedLogsPage(
                      allBlocs,
                      context.ispectL10n.talker_type_bloc,
                    ),
                    subtitleWidget: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.ispectL10n.talker_bloc_events_count(
                            blocEvents.length,
                          ),
                          style: TextStyle(
                            color: getTypeColor(
                              isDark: options.themeMode == ThemeMode.dark,
                              key: "bloc-event",
                            ),
                          ),
                        ),
                        Text(
                          context.ispectL10n.talker_bloc_transition_count(
                            blocTransitions.length,
                          ),
                          style: TextStyle(
                            color: getTypeColor(
                              isDark: options.themeMode == ThemeMode.dark,
                              key: "bloc-transition",
                            ),
                          ),
                        ),
                        Text(
                          context.ispectL10n.talker_bloc_create_count(
                            blocCreates.length,
                          ),
                          style: TextStyle(
                            color: getTypeColor(
                              isDark: options.themeMode == ThemeMode.dark,
                              key: "bloc-create",
                            ),
                          ),
                        ),
                        Text(
                          context.ispectL10n.talker_bloc_close_count(
                            blocCloses.length,
                          ),
                          style: TextStyle(
                            color: getTypeColor(
                              isDark: options.themeMode == ThemeMode.dark,
                              key: "bloc-close",
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (errors.isNotEmpty) ...[
                const SliverToBoxAdapter(child: SizedBox(height: 10)),
                SliverToBoxAdapter(
                  child: _TalkerMonitorsCard(
                    logs: errors,
                    title: context.ispectL10n.talker_type_errors,
                    color: theme.logColors.getByType(TalkerLogType.error),
                    icon: Icons.error_outline_rounded,
                    subtitle: context.ispectL10n.talker_type_errors_count(errors.length),
                    onTap: () => openTypedLogsPage(
                      errors,
                      context.ispectL10n.talker_type_errors,
                    ),
                  ),
                ),
              ],
              if (exceptions.isNotEmpty) ...[
                const SliverToBoxAdapter(child: SizedBox(height: 10)),
                SliverToBoxAdapter(
                  child: _TalkerMonitorsCard(
                    logs: exceptions,
                    title: context.ispectL10n.talker_type_exceptions,
                    color: theme.logColors.getByType(TalkerLogType.exception),
                    icon: Icons.error_outline_rounded,
                    subtitle: context.ispectL10n.talker_type_exceptions_count(exceptions.length),
                    onTap: () => openTypedLogsPage(
                      exceptions,
                      context.ispectL10n.talker_type_exceptions,
                    ),
                  ),
                ),
              ],
              if (warnings.isNotEmpty) ...[
                const SliverToBoxAdapter(child: SizedBox(height: 10)),
                SliverToBoxAdapter(
                  child: _TalkerMonitorsCard(
                    logs: warnings,
                    title: context.ispectL10n.talker_type_warnings,
                    color: theme.logColors.getByType(TalkerLogType.warning),
                    icon: Icons.warning_amber_rounded,
                    subtitle: context.ispectL10n.talker_type_warnings_count(warnings.length),
                    onTap: () => openTypedLogsPage(
                      warnings,
                      context.ispectL10n.talker_type_warnings,
                    ),
                  ),
                ),
              ],
              if (infos.isNotEmpty) ...[
                const SliverToBoxAdapter(child: SizedBox(height: 10)),
                SliverToBoxAdapter(
                  child: _TalkerMonitorsCard(
                    logs: infos,
                    title: context.ispectL10n.talker_type_info,
                    color: theme.logColors.getByType(TalkerLogType.info),
                    icon: Icons.info_outline_rounded,
                    subtitle: context.ispectL10n.talker_type_info_count(infos.length),
                    onTap: () => openTypedLogsPage(
                      infos,
                      context.ispectL10n.talker_type_info,
                    ),
                  ),
                ),
              ],
              if (goods.isNotEmpty) ...[
                const SliverToBoxAdapter(child: SizedBox(height: 10)),
                SliverToBoxAdapter(
                  child: _TalkerMonitorsCard(
                    logs: goods,
                    title: context.ispectL10n.talker_type_good,
                    color: getTypeColor(
                      isDark: options.themeMode == ThemeMode.dark,
                      key: "good",
                    ),
                    icon: Icons.check_circle_outline_rounded,
                    subtitle: context.ispectL10n.talker_type_good_count(goods.length),
                    onTap: () => openTypedLogsPage(
                      goods,
                      context.ispectL10n.talker_type_good,
                    ),
                  ),
                ),
              ],
              if (providers.isNotEmpty) ...[
                const SliverToBoxAdapter(child: SizedBox(height: 10)),
                SliverToBoxAdapter(
                  child: _TalkerMonitorsCard(
                    logs: providers,
                    title: context.ispectL10n.talker_type_provider,
                    color: getTypeColor(
                      isDark: options.themeMode == ThemeMode.dark,
                      key: "provider",
                    ),
                    icon: Icons.cast_rounded,
                    subtitle: context.ispectL10n.talker_type_provider_count(providers.length),
                    onTap: () => openTypedLogsPage(
                      providers,
                      context.ispectL10n.talker_type_provider,
                    ),
                  ),
                ),
              ],
              if (verboseDebug.isNotEmpty) ...[
                const SliverToBoxAdapter(child: SizedBox(height: 10)),
                SliverToBoxAdapter(
                  child: _TalkerMonitorsCard(
                    logs: verboseDebug,
                    title: context.ispectL10n.talker_type_debug,
                    color: theme.logColors.getByType(TalkerLogType.verbose),
                    icon: Icons.remove_red_eye_outlined,
                    subtitle: context.ispectL10n.talker_type_debug_count(verboseDebug.length),
                    onTap: () => openTypedLogsPage(
                      verboseDebug,
                      context.ispectL10n.talker_type_debug,
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
}
