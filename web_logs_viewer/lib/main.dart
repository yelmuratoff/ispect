import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

final observer = ISpectNavigatorObserver();

void main() {
  ISpect.run(() => runApp(const MyApp()), logger: ISpectifyFlutter.init());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorObservers: [observer],
      localizationsDelegates: ISpectLocalizations.delegates(),
      theme: ThemeData(
        useMaterial3: true,
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),
      ),
      home: const MyHomePage(title: 'ISpect File Viewer'),
      builder: (context, child) => ISpectBuilder(
        isISpectEnabled: true,
        options: ISpectOptions(observer: observer),
        child: child!,
      ),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});

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
      body: const _HomeLayout(dropZone: _DropZone()),
    );
  }
}

class _HomeLayout extends StatelessWidget {
  const _HomeLayout({required this.dropZone});

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
                        child: _DropZoneContainer(child: dropZone),
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
                        child: _DropZoneContainer(child: dropZone),
                      ),
                    ),
                  ],
                );
        },
      ),
    );
  }
}

class _DropZoneContainer extends StatelessWidget {
  const _DropZoneContainer({required this.child});

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

class _DropZone extends StatefulWidget {
  const _DropZone();

  @override
  State<StatefulWidget> createState() => _DropZoneState();
}

class _DropZoneState extends State<_DropZone>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool _isDragOver = false;
  final List<Widget> _droppedWidgets = [];
  Widget _preview = const SizedBox();
  Widget _content = const _EmptyDropZoneContent();

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
          _DropZoneHeader(
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
      _content = const _EmptyDropZoneContent();
    });
  }

  DropOperation _onDropOver(DropOverEvent event) {
    setState(() {
      _isDragOver = true;
      _preview = _DropPreview(items: event.session.items);
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

        widgets.add(_DropItemHeader(item: item));

        await _processDropItem(reader, item);

        if (item.localData != null) {
          widgets.add(_LocalDataWidget(localData: item.localData!));
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
    final handler = _DropFormatHandler(state: this, reader: reader, item: item);
    await handler.process();
  }

  void _handleFile(dynamic file, String? displayName, String? mimeType) {
    _processFileStream(
      file,
      onSuccess: (content) {
        final fileInfo = _detectFileType(
          content,
          file.fileName,
          defaultDisplayName: displayName ?? 'Text',
          defaultMimeType: mimeType ?? 'text/plain',
        );
        if (mounted) {
          setState(() {
            _addWidgetToContent(
              _FileContentWidget(
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
              _ErrorWidget(title: 'Failed to decode file', error: e.toString()),
            );
          });
        }
      },
    );
  }

  void _processFileStream(
    dynamic file, {
    required void Function(String content) onSuccess,
    required void Function(Object error) onError,
  }) {
    final stream = file.getStream();
    final chunks = <Uint8List>[];

    stream.listen(
      chunks.add,
      onDone: () {
        try {
          final combinedData = _combineChunks(chunks);
          final content = utf8.decode(combinedData);
          onSuccess(content);
        } catch (e) {
          onError(e);
        }
      },
      onError: onError,
    );
  }

  ({String displayName, String mimeType}) _detectFileType(
    String content,
    String? fileName, {
    String defaultDisplayName = 'Text',
    String defaultMimeType = 'text/plain',
  }) {
    final trimmedContent = content.trim();
    final isJsonContent = _isJsonContent(trimmedContent);

    if (fileName != null) {
      final lowerFileName = fileName.toLowerCase();
      if (lowerFileName.endsWith('.json')) {
        return (displayName: 'JSON', mimeType: 'application/json');
      }
      if (lowerFileName.endsWith('.txt')) {
        if (isJsonContent) {
          return (
            displayName: 'JSON (from .txt file)',
            mimeType: 'application/json',
          );
        }
        return (displayName: 'Text', mimeType: 'text/plain');
      }
    }

    if (isJsonContent) {
      final prefix = defaultDisplayName == 'HTML'
          ? 'JSON (from HTML format)'
          : 'JSON';
      return (displayName: prefix, mimeType: 'application/json');
    }

    return (displayName: defaultDisplayName, mimeType: defaultMimeType);
  }

  bool _isJsonContent(String trimmedContent) {
    if ((trimmedContent.startsWith('{') && trimmedContent.endsWith('}')) ||
        (trimmedContent.startsWith('[') && trimmedContent.endsWith(']'))) {
      try {
        jsonDecode(trimmedContent);
        return true;
      } catch (e) {
        return trimmedContent.startsWith('{') || trimmedContent.startsWith('[');
      }
    }
    return false;
  }

  Uint8List _combineChunks(List<Uint8List> chunks) {
    final totalLength = chunks.fold<int>(0, (sum, chunk) => sum + chunk.length);
    final result = Uint8List(totalLength);
    var offset = 0;

    for (final chunk in chunks) {
      result.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }

    return result;
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
      builder: (BuildContext context) => _FileOptionsDialog(
        onPaste: _showPasteDialog,
        onPick: _showFilePicker,
      ),
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

        final fileInfo = _detectFileType(content, fileName);

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

        final mockFile = _MockFileWithPlatformFile(
          content: content,
          fileName: file.name,
          size: file.size,
          platformFile: file,
        );

        if (mounted) {
          setState(() {
            _addWidgetToContent(
              _FileContentWidget(
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
          _PasteDialog(onProcess: _processPastedContent),
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

    final mockFile = _MockFile(
      content: content,
      fileName:
          'pasted_content.${detectedFormat == 'auto' || detectedFormat == 'text' ? 'txt' : detectedFormat}',
    );

    setState(() {
      _addWidgetToContent(
        _FileContentWidget(
          content: content,
          file: mockFile,
          displayName: displayName,
          mimeType: mimeType,
        ),
      );
    });
  }
}

// ============================================================================
// DROP FORMAT HANDLER
// ============================================================================

class _DropFormatHandler {
  _DropFormatHandler({
    required this.state,
    required this.reader,
    required this.item,
  });

  final _DropZoneState state;
  final dynamic reader;
  final DropItem item;

  Future<void> process() async {
    final formatHandlers = [
      () => _tryFormat(Formats.json, 'JSON', 'application/json'),
      () => _tryFormat(Formats.plainTextFile, null, null),
      () => _tryFormat(Formats.htmlFile, 'HTML', 'text/html'),
      () => _tryFileUri(),
    ];

    for (final handler in formatHandlers) {
      if (await handler()) return;
    }

    await _tryWebFormats() || await _tryMimeTypes() || await _tryPlainText();
  }

  Future<bool> _tryFormat(
    dynamic format,
    String? displayName,
    String? mimeType,
  ) async {
    if (reader.canProvide(format)) {
      reader.getFile(
        format,
        (file) {
          if (state.mounted) state._handleFile(file, displayName, mimeType);
        },
        onError: (error) {
          ISpect.logger.error('Error reading format: $error');
        },
      );
      return true;
    }
    return false;
  }

  Future<bool> _tryFileUri() async {
    if (reader.canProvide(Formats.fileUri)) {
      reader.getValue<Uri>(
        Formats.fileUri,
        (value) {
          if (value != null && state.mounted) {
            state._addWidgetInState(_FileUriWidget(fileUri: value));
            _tryReadExternalFile(value);
          }
        },
        onError: (error) {
          ISpect.logger.error('Error reading file URI: $error');
        },
      );
      return true;
    }
    return false;
  }

  Future<bool> _tryWebFormats() async {
    for (final format in item.platformFormats) {
      if (format.startsWith('web:') || format.contains('file')) {
        ISpect.logger.info('Trying web format: $format');
        _tryReadWebFormat(format);
        return true;
      }
    }
    return false;
  }

  Future<bool> _tryMimeTypes() async {
    for (final format in item.platformFormats) {
      if (format == 'application/json' ||
          format == 'text/plain' ||
          format == 'text/json') {
        ISpect.logger.info('Found MIME type: $format');
        _tryReadMimeTypeFormat(format);
        return true;
      }
    }
    return false;
  }

  Future<bool> _tryPlainText() async {
    if (reader.canProvide(Formats.plainText)) {
      reader.getValue<String>(
        Formats.plainText,
        (value) {
          if (value != null && state.mounted) {
            final mockFile = _MockFile(
              content: value,
              fileName: 'dropped_text.txt',
            );
            state._addWidgetInState(
              _FileContentWidget(
                content: value,
                file: mockFile,
                displayName: 'Text',
                mimeType: 'text/plain',
              ),
            );
          }
        },
        onError: (error) {
          ISpect.logger.error('Error reading plain text: $error');
        },
      );
      return true;
    }
    return false;
  }

  void _tryReadExternalFile(Uri fileUri) {
    final fileName = fileUri.pathSegments.isNotEmpty
        ? fileUri.pathSegments.last
        : 'unknown';
    final extension = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : '';

    if (extension != 'txt' && extension != 'json') {
      _showError(
        _ExternalFileErrorWidget(
          fileName: fileName,
          error: 'Only .txt and .json files are supported',
        ),
      );
      return;
    }

    if (reader.canProvide(Formats.plainTextFile)) {
      reader.getFile(
        Formats.plainTextFile,
        (file) {
          state._handleFile(file, null, null);
        },
        onError: (error) {
          ISpect.logger.error('Could not read external file: $error');
          _showError(
            _ExternalFileErrorWidget(
              fileName: fileName,
              error: 'Could not read file content',
            ),
          );
        },
      );
      return;
    }

    _showError(
      _ExternalFileErrorWidget(
        fileName: fileName,
        error: 'File format not supported for content reading',
      ),
    );
  }

  void _tryReadWebFormat(String format) {
    ISpect.logger.info('Attempting to read web format: $format');

    if (reader.canProvide(Formats.json)) {
      reader.getFile(
        Formats.json,
        (file) => state._handleFile(file, 'JSON', 'application/json'),
        onError: (error) {
          ISpect.logger.error('Error reading web format as JSON: $error');
          _tryWebFormatAsPlainText(format);
        },
      );
      return;
    }

    if (reader.canProvide(Formats.plainTextFile)) {
      reader.getFile(
        Formats.plainTextFile,
        (file) => state._handleFile(file, null, null),
        onError: (error) {
          ISpect.logger.error('Error reading web format as text: $error');
          _showError(
            _FormatErrorWidget(
              type: 'Web Format',
              format: format,
              error: 'Could not read as text file',
            ),
          );
        },
      );
      return;
    }

    _tryWebFormatAsPlainText(format);
  }

  void _tryReadMimeTypeFormat(String mimeType) {
    ISpect.logger.info('Attempting to read MIME type: $mimeType');

    if (mimeType == 'application/json' && reader.canProvide(Formats.json)) {
      reader.getFile(
        Formats.json,
        (file) => state._handleFile(file, 'JSON', 'application/json'),
        onError: (error) {
          ISpect.logger.error('Error reading JSON MIME type: $error');
          _tryReadAsPlainTextFile(mimeType);
        },
      );
      return;
    }

    if (reader.canProvide(Formats.plainTextFile)) {
      reader.getFile(
        Formats.plainTextFile,
        (file) => state._handleFile(file, null, null),
        onError: (error) {
          ISpect.logger.error('Error reading MIME type as file: $error');
          _showError(
            _FormatErrorWidget(
              type: 'MIME Type',
              format: mimeType,
              error: 'Could not read file content',
            ),
          );
        },
      );
      return;
    }

    if (reader.canProvide(Formats.plainText)) {
      reader.getValue<String>(
        Formats.plainText,
        (value) {
          if (value != null && state.mounted) {
            final displayName = mimeType == 'application/json'
                ? 'JSON'
                : 'Text';
            final mockFile = _MockFile(
              content: value,
              fileName:
                  'mime_content.${mimeType == 'application/json' ? 'json' : 'txt'}',
            );
            state._addWidgetInState(
              _FileContentWidget(
                content: value,
                file: mockFile,
                displayName: displayName,
                mimeType: mimeType,
              ),
            );
          }
        },
        onError: (error) {
          ISpect.logger.error('Error reading MIME type as text: $error');
          _showError(
            _FormatErrorWidget(
              type: 'MIME Type',
              format: mimeType,
              error: 'Could not read text content',
            ),
          );
        },
      );
      return;
    }

    _showError(
      _FormatErrorWidget(
        type: 'MIME Type',
        format: mimeType,
        error: 'MIME type not supported for reading',
      ),
    );
  }

  void _tryReadAsPlainTextFile(String mimeType) {
    if (reader.canProvide(Formats.plainTextFile)) {
      reader.getFile(
        Formats.plainTextFile,
        (file) => state._handleFile(file, null, null),
        onError: (error) {
          ISpect.logger.error('Error reading as plain text file: $error');
          _showError(
            _FormatErrorWidget(
              type: 'MIME Type',
              format: mimeType,
              error: 'Could not read as text file',
            ),
          );
        },
      );
    } else {
      _showError(
        _FormatErrorWidget(
          type: 'MIME Type',
          format: mimeType,
          error: 'Plain text file format not available',
        ),
      );
    }
  }

  void _tryWebFormatAsPlainText(String format) {
    if (reader.canProvide(Formats.plainText)) {
      reader.getValue<String>(
        Formats.plainText,
        (value) {
          if (value != null && state.mounted) {
            final mockFile = _MockFile(
              content: value,
              fileName: 'web_format_content.txt',
            );
            state._addWidgetInState(
              _FileContentWidget(
                content: value,
                file: mockFile,
                displayName: 'Web Content',
                mimeType: 'text/plain',
              ),
            );
          }
        },
        onError: (error) {
          ISpect.logger.error('Error reading web format as plain text: $error');
          _showError(
            _FormatErrorWidget(
              type: 'Web Format',
              format: format,
              error: 'Could not read as plain text',
            ),
          );
        },
      );
    } else {
      _showError(
        _FormatErrorWidget(
          type: 'Web Format',
          format: format,
          error: 'Format not supported for content reading',
        ),
      );
    }
  }

  void _showError(Widget errorWidget) {
    if (state.mounted) {
      state._addWidgetInState(errorWidget);
    }
  }
}

// ============================================================================
// WIDGETS
// ============================================================================

class _EmptyDropZoneContent extends StatelessWidget {
  const _EmptyDropZoneContent();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.file_upload_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Drop files or data here',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            'Supports images, text, files, and more',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _DropZoneHeader extends StatelessWidget {
  const _DropZoneHeader({
    required this.hasContent,
    required this.onClear,
    required this.onLoadFile,
  });

  final bool hasContent;
  final VoidCallback onClear;
  final VoidCallback onLoadFile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        spacing: 8,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.folder_open),
              Text(
                'Drop Zone',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Flexible(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              spacing: 8,
              children: [
                Flexible(
                  child: FilledButton.icon(
                    onPressed: onLoadFile,
                    icon: const Icon(Icons.upload_file_rounded, size: 16),
                    label: const Text(
                      'Load File',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                if (hasContent)
                  Flexible(
                    child: ElevatedButton.icon(
                      onPressed: onClear,
                      icon: const Icon(Icons.clear, size: 16),
                      label: const Text(
                        'Clear',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade100,
                        foregroundColor: Colors.red.shade700,
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
}

class _DropPreview extends StatelessWidget {
  const _DropPreview({required this.items});

  final List<DropItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        color: Colors.black.withValues(alpha: 0.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(50),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: ListView(
                shrinkWrap: true,
                children: items
                    .map<Widget>((e) => _DropItemInfo(dropItem: e))
                    .toList(growable: false),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DropItemHeader extends StatelessWidget {
  const _DropItemHeader({required this.item});

  final DropItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Drop Item',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
          ),
          if (item.localData != null) ...[
            const SizedBox(height: 4),
            Text(
              'Local Data: ${item.localData}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            'Available Formats: ${item.platformFormats.join(', ')}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }
}

class _FileUriWidget extends StatelessWidget {
  const _FileUriWidget({required this.fileUri});

  final Uri fileUri;

  @override
  Widget build(BuildContext context) {
    final fileName = fileUri.pathSegments.isNotEmpty
        ? fileUri.pathSegments.last
        : 'Unknown';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'File Path',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text('File Name: $fileName'),
          const SizedBox(height: 4),
          SelectableText(
            'Full Path: ${fileUri.toFilePath()}',
            style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }
}

class _LocalDataWidget extends StatelessWidget {
  const _LocalDataWidget({required this.localData});

  final Object localData;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Local Data',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(localData.toString(), style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}

class _FileContentWidget extends StatelessWidget {
  const _FileContentWidget({
    required this.content,
    required this.file,
    required this.displayName,
    required this.mimeType,
  });

  final String content;
  final dynamic file;
  final String displayName;
  final String mimeType;

  @override
  Widget build(BuildContext context) {
    final int? fileLength = _getFileLengthSafely(file);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.cyan.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.cyan.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$displayName File',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.cyan.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'MIME Type: $mimeType',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          if (file.fileName != null) ...[
            Text('File Name: ${file.fileName}'),
            const SizedBox(height: 4),
          ],
          if (fileLength != null) ...[
            Text('File Size: ${_formatFileSize(fileLength)}'),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 32),
          FilledButton(
            onPressed: () {
              dynamic data;
              if (mimeType == 'application/json') {
                data = jsonDecode(content);
              } else {
                data = content;
              }
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => JsonScreen(
                    data: {
                      'display_name': displayName,
                      'mime_type': mimeType,
                      'file_name': file.fileName,
                      if (fileLength != null)
                        'size': _formatFileSize(fileLength),
                      'content': data,
                    },
                  ),
                ),
              );
            },
            child: const Text('View in JSON Viewer'),
          ),
        ],
      ),
    );
  }

  int? _getFileLengthSafely(dynamic file) {
    try {
      if (file.runtimeType.toString().contains('length')) {
        return file.length as int?;
      }
    } catch (e) {
      // Ignore
    }
    return null;
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _ErrorWidget extends StatelessWidget {
  const _ErrorWidget({required this.title, required this.error});

  final String title;
  final String error;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(fontSize: 12, color: Colors.red.shade600),
          ),
        ],
      ),
    );
  }
}

class _FormatErrorWidget extends StatelessWidget {
  const _FormatErrorWidget({
    required this.type,
    required this.format,
    required this.error,
  });

  final String type;
  final String format;
  final String error;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$type Processing',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text('$type: $format'),
          const SizedBox(height: 4),
          Text(
            'Error: $error',
            style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
          ),
          const SizedBox(height: 8),
          Text(
            'Try using the "Load File" button to paste file content directly.',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _ExternalFileErrorWidget extends StatelessWidget {
  const _ExternalFileErrorWidget({required this.fileName, required this.error});

  final String fileName;
  final String error;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'File Path Detected',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.amber.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text('File: $fileName'),
          const SizedBox(height: 4),
          Text(
            error,
            style: TextStyle(fontSize: 12, color: Colors.amber.shade700),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '💡 Как читать файлы в веб-браузере:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '1. Откройте файл в текстовом редакторе',
                  style: TextStyle(fontSize: 11, color: Colors.blue.shade700),
                ),
                Text(
                  '2. Скопируйте содержимое (Ctrl+A, Ctrl+C)',
                  style: TextStyle(fontSize: 11, color: Colors.blue.shade700),
                ),
                Text(
                  '3. Нажмите кнопку "Load File" выше и вставьте содержимое',
                  style: TextStyle(fontSize: 11, color: Colors.blue.shade700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Или перетащите файл прямо из редактора кода в эту область.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.blue.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FileOptionsDialog extends StatelessWidget {
  const _FileOptionsDialog({required this.onPaste, required this.onPick});

  final VoidCallback onPaste;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Load File Content'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose how to load your file:',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.content_paste),
            title: const Text('Paste Content'),
            subtitle: const Text(
              'Copy .txt or .json file content and paste it here',
            ),
            onTap: () {
              Navigator.of(context).pop();
              onPaste();
            },
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.content_paste),
            title: const Text('Pick Files'),
            subtitle: const Text('Select .txt or .json files from your device'),
            onTap: () {
              Navigator.of(context).pop();
              onPick();
            },
          ),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
          const Text(
            '💡 Tip: You can also drag and drop .txt or .json files directly to the drop zone above.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            '⚠️ Only .txt and .json files are supported.',
            style: TextStyle(fontSize: 12, color: Colors.orange),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class _PasteDialog extends StatefulWidget {
  const _PasteDialog({required this.onProcess});

  final void Function(String content, String format) onProcess;

  @override
  State<_PasteDialog> createState() => _PasteDialogState();
}

class _PasteDialogState extends State<_PasteDialog> {
  final TextEditingController _controller = TextEditingController();
  String _selectedFormat = 'auto';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Paste File Content'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Format: '),
                DropdownButton<String>(
                  value: _selectedFormat,
                  items: const [
                    DropdownMenuItem(value: 'auto', child: Text('Auto-detect')),
                    DropdownMenuItem(value: 'json', child: Text('JSON')),
                    DropdownMenuItem(value: 'text', child: Text('Plain Text')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedFormat = value!;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Paste your file content below:'),
            const SizedBox(height: 8),
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Paste your .txt or .json file content here...',
                ),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_controller.text.trim().isNotEmpty) {
              Navigator.of(context).pop();
              widget.onProcess(_controller.text, _selectedFormat);
            }
          },
          child: const Text('Process'),
        ),
      ],
    );
  }
}

class _DropItemInfo extends StatelessWidget {
  const _DropItemInfo({required this.dropItem});

  final DropItem dropItem;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      child: DefaultTextStyle.merge(
        style: const TextStyle(fontSize: 11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (dropItem.localData != null)
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: 'Local data: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: '${dropItem.localData}'),
                  ],
                ),
              ),
            const SizedBox(height: 4),
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text: 'Native formats: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: dropItem.platformFormats.join(', ')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// MODELS
// ============================================================================

class _MockFile {
  const _MockFile({required this.content, this.fileName});

  final String content;
  final String? fileName;
}

class _MockFileWithPlatformFile {
  const _MockFileWithPlatformFile({
    required this.content,
    this.fileName,
    this.size,
    required this.platformFile,
  });

  final String content;
  final String? fileName;
  final int? size;
  final PlatformFile platformFile;

  int? get length => size;
}
