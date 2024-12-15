import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/features/talker/presentation/pages/body_view.dart'
    as view;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// UI view for output of all Talker logs and errors
class ISpectPage extends StatefulWidget {
  const ISpectPage({
    required this.options,
    super.key,
    this.appBarTitle = 'ISpect',
    this.itemsBuilder,
  });

  /// Screen [AppBar] title
  final String? appBarTitle;

  /// Optional Builder to customize
  /// log items cards in list
  final TalkerDataBuilder? itemsBuilder;

  final ISpectOptions options;

  @override
  State<ISpectPage> createState() => _ISpectPageState();
}

class _ISpectPageState extends State<ISpectPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) => _View(
        talker: ISpect.talker,
        appBarTitle: widget.appBarTitle,
        options: widget.options,
      );
}

class _View extends StatelessWidget {
  const _View({
    required this.talker,
    required this.appBarTitle,
    required this.options,
  });

  final Talker talker;
  final String? appBarTitle;
  final ISpectOptions options;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: ISpect.read(context).theme.backgroundColor(context),
        body: view.ISpectPageView(
          talker: talker,
          appBarTitle: appBarTitle,
          appBarLeading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(
              Icons.arrow_back_rounded,
            ),
          ),
          options: options,
        ),
      );
}

Future<XFile> writeImageToStorage(Uint8List feedbackScreenshot) async {
  final output = await getTemporaryDirectory();
  final screenshotFilePath =
      '${output.path}/feedback${feedbackScreenshot.hashCode}.png';
  final screenshotFile = File(screenshotFilePath);
  await screenshotFile.writeAsBytes(feedbackScreenshot);
  return XFile(screenshotFilePath, bytes: feedbackScreenshot);
}
