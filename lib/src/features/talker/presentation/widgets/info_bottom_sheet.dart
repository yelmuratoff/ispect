import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/widgets/widget/base_bottom_sheet.dart';
import 'package:ispect/src/features/talker/bloc/log_descriptions/log_descriptions_cubit.dart';

class ISpectLogsInfoBottomSheet extends StatelessWidget {
  const ISpectLogsInfoBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final iSpect = ISpect.read(context);
    return BaseBottomSheet(
      title: context.ispectL10n.talkerLogsInfo,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.6,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 16, top: 8),
          child: CustomScrollView(
            primary: false,
            slivers: [
              BlocBuilder<LogDescriptionsCubit, LogDescriptionsState>(
                builder: (context, state) {
                  if (state is LogDescriptionsLoading) {
                    return const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 32),
                          child: CircularProgressIndicator(
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                      ),
                    );
                  } else if (state is LogDescriptionsLoaded) {
                    return SliverToBoxAdapter(
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
                                        color: iSpect.theme.getTypeColor(
                                          context,
                                          key: 'error',
                                        ),
                                      ),
                                    ),
                                    TextSpan(
                                      text: ' critical,',
                                      style: TextStyle(
                                        color: iSpect.theme.getTypeColor(
                                          context,
                                          key: 'critical',
                                        ),
                                      ),
                                    ),
                                    TextSpan(
                                      text: ' exception,',
                                      style: TextStyle(
                                        color: iSpect.theme.getTypeColor(
                                          context,
                                          key: 'exception',
                                        ),
                                      ),
                                    ),
                                    TextSpan(
                                      text: ' info,',
                                      style: TextStyle(
                                        color: iSpect.theme.getTypeColor(
                                          context,
                                          key: 'info',
                                        ),
                                      ),
                                    ),
                                    TextSpan(
                                      text: ' print,',
                                      style: TextStyle(
                                        color: iSpect.theme.getTypeColor(
                                          context,
                                          key: 'print',
                                        ),
                                      ),
                                    ),
                                    TextSpan(
                                      text: ' route,',
                                      style: TextStyle(
                                        color: iSpect.theme.getTypeColor(
                                          context,
                                          key: 'route',
                                        ),
                                      ),
                                    ),
                                    TextSpan(
                                      text: ' ${context.ispectL10n.talkerTypeHttp}.',
                                      style: TextStyle(
                                        color: iSpect.theme.getTypeColor(
                                          context,
                                          key: 'http-request',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                TextSpan(
                                  text: '\n${context.ispectL10n.otherLogsForDevelopers}.',
                                ),
                              ],
                            ),
                          ),
                          const Gap(16),
                          ...state.logDescriptions.map(
                            (log) => _LogKey(
                              log.key,
                              log.description,
                              log.key,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
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
  Widget build(BuildContext context) {
    final iSpect = ISpect.read(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: title,
                style: TextStyle(
                  color: iSpect.theme.getTypeColor(
                    context,
                    key: logKey,
                  ),
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
}
