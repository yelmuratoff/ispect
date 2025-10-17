import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

import '../../../../core/models/models.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/drop_format_handler.dart';
import '../widgets/widgets.dart';

class DropZone extends StatefulWidget {
  const DropZone({super.key});

  @override
  State<StatefulWidget> createState() => DropZoneState();
}

class DropZoneState extends State<DropZone> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool _isDragOver = false;
  final List<Widget> _droppedWidgets = [];
  Widget _preview = const SizedBox();
  Widget _content = const EmptyDropZoneContent();

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return DropRegion(
      formats: const [...Formats.standardFormats],
      hitTestBehavior: HitTestBehavior.opaque,
      onDropOver: _onDropOver,
      onPerformDrop: _onPerformDrop,
      onDropLeave: _onDropLeave,
      child: Column(
        children: [
          DropZoneHeader(
            hasContent: _droppedWidgets.isNotEmpty,
            onClear: _clearDroppedItems,
            onLoadFile: _showFileOptionsDialog,
          ),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(child: _content),
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      opacity: _isDragOver ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: _preview,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _clearDroppedItems() {
    setState(() {
      _droppedWidgets.clear();
      _content = const EmptyDropZoneContent();
    });
  }

  DropOperation _onDropOver(DropOverEvent event) {
    setState(() {
      _isDragOver = true;
      _preview = DropPreview(items: event.session.items);
    });
    return event.session.allowedOperations.firstOrNull ?? DropOperation.none;
  }

  Future<void> _onPerformDrop(PerformDropEvent event) async {
    if (!mounted) return;

    try {
      final widgets = <Widget>[];

      for (final item in event.session.items) {
        final reader = item.dataReader!;

        ISpect.logger.info(
          'Available formats: ${item.platformFormats.join(', ')}',
        );

        widgets.add(DropItemHeader(item: item));

        await _processDropItem(reader, item);

        if (item.localData != null) {
          widgets.add(LocalDataWidget(localData: item.localData!));
        }
      }

      if (mounted) {
        setState(() {
          _droppedWidgets.addAll(widgets);
          _updateContent();
        });
      }
    } catch (e) {
      ISpect.logger.error('Error in _onPerformDrop: $e');
    }
  }

  Future<void> _processDropItem(dynamic reader, DropItem item) async {
    final handler = DropFormatHandler(
      reader: reader,
      item: item,
      onHandleFile: _handleFile,
      onAddWidget: _addWidgetInState,
    );
    await handler.process();
  }

  void _handleFile(dynamic file, String? displayName, String? mimeType) {
    processFileStream(
      file,
      onSuccess: (content) {
        final fileInfo = detectFileType(
          content,
          file.fileName,
          defaultDisplayName: displayName ?? 'Text',
          defaultMimeType: mimeType ?? 'text/plain',
        );
        if (mounted) {
          setState(() {
            _addWidgetToContent(
              FileContentWidget(
                content: content,
                file: file,
                displayName: fileInfo.displayName,
                mimeType: fileInfo.mimeType,
              ),
            );
          });
        }
      },
      onError: (e) {
        ISpect.logger.error('Error processing file: $e');
        if (mounted) {
          setState(() {
            _addWidgetToContent(
              FileErrorWidget(
                title: 'Failed to decode file',
                error: e.toString(),
              ),
            );
          });
        }
      },
    );
  }

  void _addWidgetToContent(Widget widget) {
    _droppedWidgets.add(widget);
    _updateContent();
  }

  void _addWidgetInState(Widget widget) {
    setState(() {
      _addWidgetToContent(widget);
    });
  }

  void _updateContent() {
    _content = CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(10),
          sliver: SliverList(
            delegate: SliverChildListDelegate(
              _droppedWidgets.toList(growable: false),
            ),
          ),
        ),
      ],
    );
  }

  void _onDropLeave(DropEvent event) {
    setState(() {
      _isDragOver = false;
      _preview = const SizedBox();
    });
  }

  void _showFileOptionsDialog() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) =>
          FileOptionsDialog(onPaste: _showPasteDialog, onPick: _showFilePicker),
    );
  }

  Future<void> _showFilePicker() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['txt', 'json'],
      );

      if (result == null || result.files.isEmpty || !mounted) return;

      for (final PlatformFile file in result.files) {
        if (!mounted) return;

        final String fileName = file.name.toLowerCase();
        if (!fileName.endsWith('.txt') && !fileName.endsWith('.json')) {
          _showSnackBar('Unsupported file type: ${file.name}', Colors.orange);
          continue;
        }

        if (file.size > 10 * 1024 * 1024) {
          _showSnackBar('File too large: ${file.name} (max 10MB)', Colors.red);
          continue;
        }

        String? content;
        if (kIsWeb && file.bytes != null) {
          try {
            content = utf8.decode(file.bytes!);
          } catch (e) {
            ISpect.logger.error('Error decoding file bytes: $e');
            _showSnackBar('Error reading file: ${file.name}', Colors.red);
            continue;
          }
        } else if (!kIsWeb) {
          _showSnackBar(
            'File reading from path is not supported on web',
            Colors.orange,
          );
          continue;
        }

        if (content == null || content.isEmpty) {
          _showSnackBar(
            'Empty or unreadable file: ${file.name}',
            Colors.orange,
          );
          continue;
        }

        final fileInfo = detectFileType(content, fileName);

        if (fileInfo.mimeType == 'application/json') {
          try {
            jsonDecode(content);
          } catch (e) {
            _showSnackBar(
              'Warning: ${file.name} contains invalid JSON',
              Colors.orange,
            );
          }
        }

        final mockFile = MockFileWithPlatformFile(
          content: content,
          fileName: file.name,
          size: file.size,
          platformFile: file,
        );

        if (mounted) {
          setState(() {
            _addWidgetToContent(
              FileContentWidget(
                content: content!,
                file: mockFile,
                displayName: fileInfo.displayName,
                mimeType: fileInfo.mimeType,
              ),
            );
          });
          _showSnackBar('Loaded file: ${file.name}', Colors.green);
        }
      }
    } catch (e) {
      ISpect.logger.error('Error in file picker: $e');
      if (mounted) {
        _showSnackBar('Error opening file picker: $e', Colors.red);
      }
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showPasteDialog() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) =>
          PasteDialog(onProcess: _processPastedContent),
    );
  }

  void _processPastedContent(String content, String format) {
    final trimmedContent = content.trim();
    String detectedFormat = format;

    if (format == 'auto') {
      if ((trimmedContent.startsWith('{') && trimmedContent.endsWith('}')) ||
          (trimmedContent.startsWith('[') && trimmedContent.endsWith(']'))) {
        detectedFormat = 'json';
      }
    }

    final displayName = detectedFormat == 'json' ? 'JSON' : 'Text';
    final mimeType = detectedFormat == 'json'
        ? 'application/json'
        : 'text/plain';

    final mockFile = MockFile(
      content: content,
      fileName:
          'pasted_content.${detectedFormat == 'auto' || detectedFormat == 'text' ? 'txt' : detectedFormat}',
    );

    setState(() {
      _addWidgetToContent(
        FileContentWidget(
          content: content,
          file: mockFile,
          displayName: displayName,
          mimeType: mimeType,
        ),
      );
    });
  }
}
