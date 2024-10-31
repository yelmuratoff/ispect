import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/talker_data.dart';
import 'package:ispect/src/common/widgets/ai_loader/ai_loader.dart';
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
        logs: ISpect.talker.history.map((e) => e.generateText()).toList().toString(),
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
          title: const Text('AI Reporter'),
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
                  // builder: (_, __) => ColumnBuilder(
                  //   itemCount: ISpect.talker.history.length,
                  //   itemBuilder: (_, index) {
                  //     final item = ISpect.talker.history[index];
                  //     return Card(
                  //       child: ListTile(
                  //         title: Text(item.title ?? ''),
                  //         subtitle: Text(item.generateText()),
                  //       ),
                  //     );
                  //   },
                  // ),
                  builder: (_, state) {
                    if (state is AiReporterLoading) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 64),
                        child: AiLoaderWidget(),
                      );
                    } else if (state is AiReporterLoaded) {
                      return MarkdownBody(data: state.report);
                    } else if (state is AiReporterError) {
                      return Text(state.message);
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
