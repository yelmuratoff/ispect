import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/utils/get_data_color.dart';
import 'package:ispect/src/common/widgets/widget/base_bottom_sheet.dart';

class ISpectLogsInfoBottomSheet extends StatelessWidget {
  const ISpectLogsInfoBottomSheet({super.key});

  @override
  Widget build(BuildContext context) => BaseBottomSheet(
        title: context.ispectL10n.talkerLogsInfo,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.6,
          ),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16)
                .copyWith(bottom: 16, top: 8),
            child: CustomScrollView(
              primary: false,
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '${context.ispectL10n.testerLogDesc}:',
                              children: [
                                TextSpan(
                                  text: ' error,',
                                  style: TextStyle(
                                    color: getTypeColor(
                                      isDark: context.isDarkMode,
                                      key: 'error',
                                    ),
                                  ),
                                ),
                                TextSpan(
                                  text: ' critical,',
                                  style: TextStyle(
                                    color: getTypeColor(
                                      isDark: context.isDarkMode,
                                      key: 'critical',
                                    ),
                                  ),
                                ),
                                TextSpan(
                                  text: ' exception,',
                                  style: TextStyle(
                                    color: getTypeColor(
                                      isDark: context.isDarkMode,
                                      key: 'exception',
                                    ),
                                  ),
                                ),
                                TextSpan(
                                  text: ' info,',
                                  style: TextStyle(
                                    color: getTypeColor(
                                      isDark: context.isDarkMode,
                                      key: 'info',
                                    ),
                                  ),
                                ),
                                TextSpan(
                                  text: ' print,',
                                  style: TextStyle(
                                    color: getTypeColor(
                                      isDark: context.isDarkMode,
                                      key: 'print',
                                    ),
                                  ),
                                ),
                                TextSpan(
                                  text: ' route,',
                                  style: TextStyle(
                                    color: getTypeColor(
                                      isDark: context.isDarkMode,
                                      key: 'route',
                                    ),
                                  ),
                                ),
                                TextSpan(
                                  text:
                                      ' ${context.ispectL10n.talkerTypeHttp}.',
                                  style: TextStyle(
                                    color: getTypeColor(
                                      isDark: context.isDarkMode,
                                      key: 'http-request',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            TextSpan(
                              text:
                                  '\n${context.ispectL10n.otherLogsForDevelopers}.',
                            ),
                          ],
                        ),
                      ),
                      const Gap(16),
                      Text(
                        context.ispectL10n.common,
                        style: TextStyle(
                          color: context.ispectTheme.textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Gap(8),
                      ...[
                        _LogKey(
                          '1. error',
                          context.ispectL10n.errorLogDesc,
                          'error',
                        ),
                        _LogKey(
                          '2. critical',
                          context.ispectL10n.criticalLogDesc,
                          'critical',
                        ),
                        _LogKey(
                          '3. info',
                          context.ispectL10n.infoLogDesc,
                          'info',
                        ),
                        _LogKey(
                          '4. debug',
                          context.ispectL10n.debugLogDesc,
                          'debug',
                        ),
                        _LogKey(
                          '5. verbose',
                          context.ispectL10n.verboseLogDesc,
                          'verbose',
                        ),
                        _LogKey(
                          '6. warning',
                          context.ispectL10n.warningLogDesc,
                          'warning',
                        ),
                        _LogKey(
                          '7. exception',
                          context.ispectL10n.exceptionLogDesc,
                          'exception',
                        ),
                        _LogKey(
                          '8. good',
                          context.ispectL10n.goodLogDesc,
                          'good',
                        ),
                        _LogKey(
                          '9. route',
                          context.ispectL10n.routeLogDesc,
                          'route',
                        ),
                        _LogKey(
                          '10. print',
                          context.ispectL10n.printLogDesc,
                          'print',
                        ),
                      ],
                      const Gap(16),
                      Text(
                        context.ispectL10n.talkerTypeHttp,
                        style: TextStyle(
                          color: context.ispectTheme.textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Gap(8),
                      ...[
                        _LogKey(
                          '1. http-request',
                          context.ispectL10n.httpRequestLogDesc,
                          'http-request',
                        ),
                        _LogKey(
                          '2. http-response',
                          context.ispectL10n.httpResponseLogDesc,
                          'http-response',
                        ),
                        _LogKey(
                          '3. http-error',
                          context.ispectL10n.httpErrorLogDesc,
                          'http-error',
                        ),
                      ],
                      const Gap(16),
                      Text(
                        context.ispectL10n.talkerTypeBloc,
                        style: TextStyle(
                          color: context.ispectTheme.textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Gap(8),
                      ...[
                        _LogKey(
                          '1. bloc-event',
                          context.ispectL10n.blocEventLogDesc,
                          'bloc-event',
                        ),
                        _LogKey(
                          '2. bloc-transition',
                          context.ispectL10n.blocTransitionLogDesc,
                          'bloc-transition',
                        ),
                        _LogKey(
                          '3. bloc-close',
                          context.ispectL10n.blocCloseLogDesc,
                          'bloc-close',
                        ),
                        _LogKey(
                          '4. bloc-create',
                          context.ispectL10n.blocCreateLogDesc,
                          'bloc-create',
                        ),
                      ],
                      const Gap(16),
                      Text(
                        context.ispectL10n.talkerTypeRiverpod,
                        style: TextStyle(
                          color: context.ispectTheme.textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Gap(8),
                      ...[
                        _LogKey(
                          '1. riverpod-add',
                          context.ispectL10n.riverpodAddLogDesc,
                          'riverpod-add',
                        ),
                        _LogKey(
                          '2. riverpod-update',
                          context.ispectL10n.riverpodUpdateLogDesc,
                          'riverpod-update',
                        ),
                        _LogKey(
                          '3. riverpod-dispose',
                          context.ispectL10n.riverpodDisposeLogDesc,
                          'riverpod-dispose',
                        ),
                        _LogKey(
                          '4. riverpod-fail',
                          context.ispectL10n.riverpodFailLogDesc,
                          'riverpod-fail',
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _LogKey extends StatelessWidget {
  const _LogKey(
    this.title,
    this.description,
    this.logKey,
  );
  final String title;
  final String description;
  final String logKey;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: title,
                  style: TextStyle(
                    color:
                        getTypeColor(isDark: context.isDarkMode, key: logKey),
                  ),
                ),
                TextSpan(
                  text: ' - $description',
                  style: TextStyle(color: context.ispectTheme.textColor),
                ),
              ],
            ),
          ),
          const Gap(8),
        ],
      );
}
