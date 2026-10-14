import 'dart:async';
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
import '../../domain/drop_outcome.dart';
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
  final FileReadTracker _reads = FileReadTracker();

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
    unawaited(_reads.cancelAll());
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

    final generation = _reads.generation;
    try {
      final widgets = <Widget>[];

      for (final item in event.session.items) {
        if (item.dataReader == null) continue;

        ISpect.logger.info(
          'Available formats: ${item.platformFormats.join(', ')}',
        );

        widgets.add(DropItemHeader(item: item));

        await DropFormatHandler(
          item: item,
          onOutcome: (outcome) => _onDropOutcome(outcome, generation),
        ).process();

        final localData = item.localData;
        if (localData != null) {
          widgets.add(LocalDataWidget(localData: localData));
        }
      }

      if (mounted && _reads.isCurrent(generation)) {
        setState(() {
          _droppedWidgets.addAll(widgets);
          _updateContent();
        });
      }
    } catch (e, st) {
      ISpect.logger.handle(
        message: 'Error in _onPerformDrop',
        exception: e,
        stackTrace: st,
      );
    }
  }

  void _onDropOutcome(DropOutcome outcome, int generation) {
    if (!_reads.isCurrent(generation)) return;
    switch (outcome) {
      case DroppedFile():
        _handleFile(outcome, generation);
      case DroppedFileUri(:final uri):
        _addWidgetInState(FileUriWidget(fileUri: uri));
      case DroppedText():
        _addWidgetInState(
          FileContentWidget(
            content: outcome.content,
            file: MockFile(
              content: outcome.content,
              fileName: outcome.fileName,
            ),
            inspection: inspectAs(outcome.content, (
              displayName: outcome.displayName,
              mimeType: outcome.mimeType,
            )),
          ),
        );
      case ExternalFileFailure(:final fileName, :final error):
        _addWidgetInState(
          ExternalFileErrorWidget(fileName: fileName, error: error),
        );
      case DropFormatFailure(:final type, :final format, :final error):
        _addWidgetInState(
          FormatErrorWidget(type: type, format: format, error: error),
        );
    }
  }

  void _handleFile(DroppedFile file, int generation) {
    _reads.read(
      file,
      onSuccess: (content) async {
        final inspection = await inspectFileContentInBackground(
          content,
          file.fileName,
          defaultDisplayName: file.displayName ?? 'Text',
          defaultMimeType: file.mimeType ?? 'text/plain',
        );
        if (!_reads.isCurrent(generation)) return;
        _addWidgetInState(
          FileContentWidget(
            content: content,
            file: file,
            inspection: inspection,
          ),
        );
      },
      onError: (e) {
        ISpect.logger.error('Error processing file: $e');
        if (!_reads.isCurrent(generation)) return;
        _addWidgetInState(
          FileErrorWidget(title: 'Failed to decode file', error: e.toString()),
        );
      },
    );
  }

  void _addWidgetToContent(Widget widget) {
    _droppedWidgets.add(widget);
    _updateContent();
  }

  void _addWidgetInState(Widget widget) {
    if (!mounted) return;
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

  @override
  void dispose() {
    unawaited(_reads.cancelAll());
    super.dispose();
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
      final FilePickerResult? result = await FilePicker.pickFiles(
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

        if (file.size > maxLoadableFileSize) {
          _showSnackBar(
            'File too large: ${file.name} '
            '(max ${formatFileSize(maxLoadableFileSize)})',
            Colors.red,
          );
          continue;
        }

        String? content;
        final fileBytes = file.bytes;
        if (kIsWeb && fileBytes != null) {
          try {
            content = utf8.decode(fileBytes);
          } catch (e, st) {
            ISpect.logger.handle(
              message: 'Error decoding file bytes',
              exception: e,
              stackTrace: st,
            );
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

        final validContent = content;
        final generation = _reads.generation;
        final inspection = await inspectFileContentInBackground(
          validContent,
          fileName,
        );
        if (!mounted) return;
        if (!_reads.isCurrent(generation)) continue;

        if (inspection.jsonError != null) {
          _showSnackBar(
            'Warning: ${file.name} contains invalid JSON',
            Colors.orange,
          );
        }

        final mockFile = MockFileWithPlatformFile(
          content: validContent,
          fileName: file.name,
          size: file.size,
          platformFile: file,
        );

        if (mounted) {
          setState(() {
            _addWidgetToContent(
              FileContentWidget(
                content: validContent,
                file: mockFile,
                inspection: inspection,
              ),
            );
          });
          _showSnackBar('Loaded file: ${file.name}', Colors.green);
        }
      }
    } catch (e, st) {
      ISpect.logger.handle(
        message: 'Error in file picker',
        exception: e,
        stackTrace: st,
      );
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
    final inspection = switch (format) {
      'auto' => inspectFileContent(content, null),
      'json' => inspectAs(content, (
        displayName: 'JSON',
        mimeType: 'application/json',
      )),
      _ => inspectAs(content, (displayName: 'Text', mimeType: 'text/plain')),
    };

    final mockFile = MockFile(
      content: content,
      fileName: 'pasted_content.${inspection.isJson ? 'json' : 'txt'}',
    );

    _addWidgetInState(
      FileContentWidget(
        content: content,
        file: mockFile,
        inspection: inspection,
      ),
    );
  }
}
