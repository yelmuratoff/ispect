import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:gap/gap.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/extensions/talker_data.dart';
import 'package:ispect/src/common/utils/date_utils.dart';
import 'package:ispect/src/common/utils/history.dart';
import 'package:ispect/src/common/widgets/ai_loader/ai_loader.dart';
import 'package:ispect/src/common/widgets/ai_loader/star_painter.dart';
import 'package:ispect/src/features/ai/bloc/ai_reporter/ai_reporter_cubit.dart';
import 'package:ispect/src/features/ai/core/data/models/log_report.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      BlocProvider.of<AiReporterCubit>(context).generateReport(
        payload: AiLogsPayload(
          possibleKeys:
              ISpect.read(context).theme.colors(context).keys.toList(),
          now: DateTime.now(),
          logsText: ISpect.talker.history.reversed
              .map((e) => e.generateText())
              .toList()
              .toString(),
          locale: ISpect.read(context).options.locale.languageCode,
        ),
      );
    });
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
                child: const SizedBox(width: 24, height: 24),
              ),
              const Gap(12),
              const Text(
                'AI Reporter',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.downloading_rounded),
              onPressed: _downloadLogs,
            ),
            if (_report != null)
              IconButton(
                icon: const Icon(Icons.share_outlined),
                onPressed: _downloadReport,
              ),
          ],
        ),
        body: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 16),
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
                              BlocProvider.of<AiReporterCubit>(context)
                                  .generateReport(
                                payload: AiLogsPayload(
                                  possibleKeys: ISpect.read(context)
                                      .theme
                                      .colors(context)
                                      .keys
                                      .toList(),
                                  now: DateTime.now(),
                                  logsText: ISpect.talker.history.reversed
                                      .map((e) => e.generateText())
                                      .toList()
                                      .toString(),
                                  locale: ISpect.read(context)
                                      .options
                                      .locale
                                      .languageCode,
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
                              BlocProvider.of<AiReporterCubit>(context)
                                  .generateReport(
                                payload: AiLogsPayload(
                                  possibleKeys: ISpect.read(context)
                                      .theme
                                      .colors(context)
                                      .keys
                                      .toList(),
                                  now: DateTime.now(),
                                  logsText: ISpect.talker.history.reversed
                                      .map((e) => e.generateText())
                                      .toList()
                                      .toString(),
                                  locale: ISpect.read(context)
                                      .options
                                      .locale
                                      .languageCode,
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

  Future<void> _downloadLogs() async {
    final logs =
        '''AI Reporter\nLogs:\n${ISpect.talker.history.formattedText()}}''';
    final file = await generateFile(logs, name: 'ai-reporter-logs');

    final xFile = XFile(file.path, name: file.path.split('/').last);

    await Share.shareXFiles([xFile]);
  }

  Future<void> _downloadReport() async {
    final report = '''AI Reporter\nReport:\n$_report''';
    final file = await generateFile(report, name: 'ai-reporter-report');

    final xFile = XFile(file.path, name: file.path.split('/').last);

    await Share.shareXFiles([xFile]);
  }
}