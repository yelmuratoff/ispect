import 'package:flutter/material.dart';

import 'drop_zone.dart';

class FileViewerPage extends StatelessWidget {
  const FileViewerPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: const HomeLayout(dropZone: DropZone()),
    );
  }
}

class HomeLayout extends StatelessWidget {
  const HomeLayout({super.key, required this.dropZone});

  final Widget dropZone;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 500;
          return isNarrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16).copyWith(top: 0),
                        child: DropZoneContainer(child: dropZone),
                      ),
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  textDirection: TextDirection.rtl,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: DropZoneContainer(child: dropZone),
                      ),
                    ),
                  ],
                );
        },
      ),
    );
  }
}

class DropZoneContainer extends StatelessWidget {
  const DropZoneContainer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blueGrey.shade200),
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }
}
