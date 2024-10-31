import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:gap/gap.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/extensions/talker_data.dart';
import 'package:ispect/src/common/widgets/ai_loader/ai_loader.dart';
import 'package:ispect/src/common/widgets/ai_loader/star_painter.dart';
import 'package:ispect/src/features/talker/bloc/ai_reporter/ai_reporter_cubit.dart';
import 'package:ispect/src/features/talker/core/data/models/log_report.dart';
import 'package:share_plus/share_plus.dart';

class AiReporterPage extends StatefulWidget {
  const AiReporterPage({super.key});

  @override
  State<AiReporterPage> createState() => _AiReporterPageState();
}

class _AiReporterPageState extends State<AiReporterPage> {
  String? _report;

  @override
  void initState() {
    super.initState();
    BlocProvider.of<AiReporterCubit>(context).generateReport(
      payload: AiLogsPayload(
        logsText: ISpect.talker.history.reversed.map((e) => e.generateText()).toList().toString(),
        locale: ISpect.read(context).options.locale.languageCode,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Row(
            children: [
              CustomPaint(
                painter: AiLoaderPainter(),
                child: const SizedBox(width: 32, height: 32),
              ),
              const Gap(12),
              const Text(
                'AI Reporter',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            if (_report != null)
              IconButton(
                icon: const Icon(Icons.share_outlined),
                onPressed: () {
                  Share.share(_report!);
                },
              ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BlocConsumer<AiReporterCubit, AiReporterState>(
                  listener: (_, state) {
                    if (state is AiReporterLoaded) {
                      setState(() {
                        _report = state.report;
                      });
                    }
                  },
                  builder: (_, state) {
                    if (state is AiReporterLoading) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 64),
                        child: AiLoaderWidget(),
                      );
                    } else if (state is AiReporterLoaded) {
                      return Column(
                        children: [
                          MarkdownBody(data: state.report),
                          const Gap(16),
                          ElevatedButton(
                            onPressed: () {
                              BlocProvider.of<AiReporterCubit>(context).generateReport(
                                payload: AiLogsPayload(
                                  logsText:
                                      ISpect.talker.history.reversed.map((e) => e.generateText()).toList().toString(),
                                  locale: ISpect.read(context).options.locale.languageCode,
                                ),
                              );
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.refresh),
                                const Gap(8),
                                Text(context.ispectL10n.retry),
                              ],
                            ),
                          ),
                        ],
                      );
                    } else if (state is AiReporterError) {
                      return Column(
                        children: [
                          Text(state.message),
                          ElevatedButton(
                            onPressed: () {
                              BlocProvider.of<AiReporterCubit>(context).generateReport(
                                payload: AiLogsPayload(
                                  logsText:
                                      ISpect.talker.history.reversed.map((e) => e.generateText()).toList().toString(),
                                  locale: ISpect.read(context).options.locale.languageCode,
                                ),
                              );
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.refresh),
                                const Gap(8),
                                Text(context.ispectL10n.retry),
                              ],
                            ),
                          ),
                        ],
                      );
                    } else {
                      return const SizedBox.shrink();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      );
}
