import 'dart:convert';
import 'dart:io' show File;
import 'dart:ui' as ui;

import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

void main() async {
  ISpect.run(() => runApp(const MyApp()), logger: ISpectifyFlutter.init());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: ISpectLocalizations.localizationDelegates([]),
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
      builder: (context, child) {
        child = ISpectBuilder(child: child!);
        return child; // Ensure child is not null
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class DragableWidget extends StatefulWidget {
  const DragableWidget({
    super.key,
    required this.name,
    required this.color,
    required this.dragItemProvider,
  });

  final String name;
  final Color color;
  final DragItemProvider dragItemProvider;

  @override
  State<DragableWidget> createState() => _DragableWidgetState();
}

class _DragableWidgetState extends State<DragableWidget> {
  bool _dragging = false;

  Future<DragItem?> provideDragItem(DragItemRequest request) async {
    final item = await widget.dragItemProvider(request);
    if (item != null) {
      void updateDraggingState() {
        setState(() {
          _dragging = request.session.dragging.value;
        });
      }

      request.session.dragging.addListener(updateDraggingState);
      updateDraggingState();
    }
    return item;
  }

  @override
  Widget build(BuildContext context) {
    return DragItemWidget(
      allowedOperations: () => [
        DropOperation.copy,
        DropOperation.move,
        DropOperation.link,
      ],
      canAddItemToExistingSession: true,
      dragItemProvider: provideDragItem,
      child: DraggableWidget(
        child: AnimatedOpacity(
          opacity: _dragging ? 0.5 : 1,
          duration: const Duration(milliseconds: 200),
          child: Container(
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Text(
              widget.name,
              style: const TextStyle(fontSize: 20, color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

Future<Uint8List> createImageData(Color color) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final paint = Paint()..color = color;
  canvas.drawOval(const Rect.fromLTWH(0, 0, 200, 200), paint);
  final picture = recorder.endRecording();
  final image = await picture.toImage(200, 200);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

class HomeLayout extends StatelessWidget {
  const HomeLayout({super.key, required this.dropZone});

  final Widget dropZone;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 500) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0).copyWith(top: 0),
                    child: dropZone,
                  ),
                ),
              ],
            );
          } else {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              textDirection: TextDirection.rtl,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: dropZone,
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}

extension on DragSession {
  Future<bool> hasLocalData(Object data) async {
    final localData = await getLocalData() ?? [];
    return localData.contains(data);
  }
}

class _MyHomePageState extends State<MyHomePage> {
  final GlobalKey<_DropZoneState> _dropZoneKey = GlobalKey<_DropZoneState>();

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 1500),
      ),
    );
  }

  Future<DragItem?> textDragItem(DragItemRequest request) async {
    // For multi drag on iOS check if this item is already in the session
    if (await request.session.hasLocalData('text-item')) {
      return null;
    }
    final item = DragItem(
      localData: 'text-item',
      suggestedName: 'PlainText.txt',
    );
    item.add(Formats.plainText('Plain Text Value'));
    return item;
  }

  Future<DragItem?> imageDragItem(DragItemRequest request) async {
    // For multi drag on iOS check if this item is already in the session
    if (await request.session.hasLocalData('image-item')) {
      return null;
    }
    final item = DragItem(localData: 'image-item', suggestedName: 'Green.png');
    item.add(Formats.png(await createImageData(Colors.green)));
    return item;
  }

  Future<DragItem?> lazyImageDragItem(DragItemRequest request) async {
    // For multi drag on iOS check if this item is already in the session
    if (await request.session.hasLocalData('lazy-image-item')) {
      return null;
    }
    final item = DragItem(
      localData: 'lazy-image-item',
      suggestedName: 'LazyBlue.png',
    );
    item.add(
      Formats.png.lazy(() async {
        showMessage('Requested lazy image.');
        return await createImageData(Colors.blue);
      }),
    );
    return item;
  }

  Future<DragItem?> virtualFileDragItem(DragItemRequest request) async {
    // For multi drag on iOS check if this item is already in the session
    if (await request.session.hasLocalData('virtual-file-item')) {
      return null;
    }
    final item = DragItem(
      localData: 'virtual-file-item',
      suggestedName: 'VirtualFile.txt',
    );
    if (!item.virtualFileSupported) {
      return null;
    }
    item.addVirtualFile(
      format: Formats.plainTextFile,
      provider: (sinkProvider, progress) {
        showMessage('Requesting virtual file content.');
        final line = utf8.encode('Line in virtual file\n');
        const lines = 10;
        final sink = sinkProvider(fileSize: line.length * lines);
        for (var i = 0; i < lines; ++i) {
          sink.add(line);
        }
        sink.close();
      },
    );
    return item;
  }

  Future<DragItem?> multipleRepresentationsDragItem(
    DragItemRequest request,
  ) async {
    // For multi drag on iOS check if this item is already in the session
    if (await request.session.hasLocalData('multiple-representations-item')) {
      return null;
    }
    final item = DragItem(localData: 'multiple-representations-item');
    item.add(Formats.png(await createImageData(Colors.pink)));
    item.add(Formats.plainText("Hello World"));
    item.add(
      Formats.uri(NamedUri(Uri.parse('https://flutter.dev'), name: 'Flutter')),
    );
    return item;
  }

  Future<DragItem?> fileDragItem(DragItemRequest request) async {
    // For multi drag on iOS check if this item is already in the session
    if (await request.session.hasLocalData('file-item')) {
      return null;
    }
    final item = DragItem(localData: 'file-item', suggestedName: 'example.txt');

    final fileContent = utf8.encode('''
This is a sample file content.
You can drag and drop files to see their content.

File Information:
- Size: Multiple lines
- Type: Plain text
- Encoding: UTF-8

This demonstrates how to handle file drops with super_drag_and_drop.
''');

    item.add(Formats.plainTextFile(fileContent));
    return item;
  }

  Future<DragItem?> jsonDragItem(DragItemRequest request) async {
    // For multi drag on iOS check if this item is already in the session
    if (await request.session.hasLocalData('json-item')) {
      return null;
    }
    final item = DragItem(localData: 'json-item', suggestedName: 'data.json');

    final jsonData = {
      'name': 'Drag and Drop Example',
      'version': '1.0.0',
      'description': 'Demonstrates file and data handling',
      'features': [
        'Native drag and drop',
        'File path extraction',
        'Multiple data formats',
        'Stream handling',
      ],
      'metadata': {
        'created': DateTime.now().toIso8601String(),
        'platform': 'Flutter Web',
      },
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(jsonData);
    final jsonBytes = utf8.encode(jsonString);

    item.add(Formats.plainTextFile(jsonBytes));
    return item;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: HomeLayout(
        dropZone: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blueGrey.shade200),
            borderRadius: BorderRadius.circular(14),
          ),
          child: _DropZone(key: _dropZoneKey),
        ),
      ),
    );
  }
}

class _DropZone extends StatefulWidget {
  const _DropZone({super.key});

  @override
  State<StatefulWidget> createState() => _DropZoneState();
}

class _DropZoneState extends State<_DropZone>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return DropRegion(
      formats: const [...Formats.standardFormats],
      hitTestBehavior: HitTestBehavior.opaque,
      onDropOver: _onDropOver,
      onPerformDrop: _onPerformDrop,
      onDropLeave: _onDropLeave,
      child: Column(
        children: [
          // Header with clear button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              spacing: 8,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.folder_open),

                    const Text(
                      'Drop Zone',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
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
                          onPressed: _showFileOptionsDialog,
                          icon: const Icon(Icons.upload_file_rounded, size: 16),
                          label: const Text(
                            'Load File',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),

                      if (_droppedWidgets.isNotEmpty)
                        Flexible(
                          child: ElevatedButton.icon(
                            onPressed: _clearDroppedItems,
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
          ),
          // Drop area
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
      _content = const Center(
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
    });
  }

  DropOperation _onDropOver(DropOverEvent event) {
    setState(() {
      _isDragOver = true;
      _preview = Container(
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
                  children: event.session.items
                      .map<Widget>((e) => _DropItemInfo(dropItem: e))
                      .toList(growable: false),
                ),
              ),
            ),
          ),
        ),
      );
    });
    return event.session.allowedOperations.firstOrNull ?? DropOperation.none;
  }

  Future<void> _onPerformDrop(PerformDropEvent event) async {
    try {
      if (!mounted) {
        return;
      }

      final widgets = <Widget>[];

      for (final item in event.session.items) {
        final reader = item.dataReader!;

        // Log available formats for debugging
        ISpect.logger.info(
          'Available formats for item: ${item.platformFormats.join(', ')}',
        );

        // Process each format the item can provide
        widgets.add(_buildDropItemHeader(item));

        // Try all possible file formats for web browsers
        bool fileProcessed = false;

        // 1. First try various text file formats (most common for text/json files)
        if (!fileProcessed) {
          // Try different file formats in order of preference
          final formatChecks = [
            // JSON specific formats
            () => reader.canProvide(Formats.json) ? 'json' : null,
            // Plain text file formats
            () => reader.canProvide(Formats.plainTextFile)
                ? 'plainTextFile'
                : null,
            // HTML format (might contain JSON/text)
            () => reader.canProvide(Formats.htmlFile) ? 'htmlFile' : null,
            // Generic file format
            () => reader.canProvide(Formats.fileUri) ? 'fileUri' : null,
          ];

          for (final check in formatChecks) {
            final format = check();
            if (format != null) {
              ISpect.logger.info('Using format: $format');

              switch (format) {
                case 'json':
                  reader.getFile(
                    Formats.json,
                    (file) {
                      _handleJsonFile(file);
                    },
                    onError: (error) {
                      ISpect.logger.error('Error reading JSON file: $error');
                    },
                  );
                  break;
                case 'plainTextFile':
                  reader.getFile(
                    Formats.plainTextFile,
                    (file) {
                      _handleTextFile(file);
                    },
                    onError: (error) {
                      ISpect.logger.error(
                        'Error reading plain text file: $error',
                      );
                    },
                  );
                  break;
                case 'htmlFile':
                  reader.getFile(
                    Formats.htmlFile,
                    (file) {
                      _handleHtmlFile(file);
                    },
                    onError: (error) {
                      ISpect.logger.error('Error reading HTML file: $error');
                    },
                  );
                  break;
                case 'fileUri':
                  reader.getValue<Uri>(
                    Formats.fileUri,
                    (value) {
                      if (value != null && mounted) {
                        setState(() {
                          _addWidgetToContent(_buildFileUriWidget(value));
                        });
                        // Try to read the actual file content if available
                        _tryReadExternalFile(reader, value);
                      }
                    },
                    onError: (error) {
                      ISpect.logger.error('Error reading file URI: $error');
                    },
                  );
                  break;
              }
              fileProcessed = true;
              break;
            }
          }
        }

        // 2. Try web-specific formats for files dropped from file system
        if (!fileProcessed) {
          // Try to find web:file or similar formats
          for (final format in item.platformFormats) {
            if (format.startsWith('web:') || format.contains('file')) {
              ISpect.logger.info('Trying to read web format: $format');
              // Try to read as file using a custom approach
              _tryReadWebFormat(reader, format, item);
              fileProcessed = true;
              break;
            }
          }
        }

        // 3. Handle specific MIME types (application/json, text/plain, etc.)
        if (!fileProcessed) {
          for (final format in item.platformFormats) {
            if (format == 'application/json' ||
                format == 'text/plain' ||
                format == 'text/json') {
              ISpect.logger.info('Found MIME type: $format');
              _tryReadMimeTypeFormat(reader, format, item);
              fileProcessed = true;
              break;
            }
          }
        }

        // 4. Handle plain text as fallback
        if (!fileProcessed && reader.canProvide(Formats.plainText)) {
          reader.getValue<String>(
            Formats.plainText,
            (value) {
              if (value != null && mounted) {
                final mockFile = _MockFile(
                  content: value,
                  fileName: 'dropped_text.txt',
                );
                setState(() {
                  _addWidgetToContent(
                    _buildGenericTextFileWidget(
                      value,
                      mockFile,
                      'Text',
                      'text/plain',
                    ),
                  );
                });
              }
            },
            onError: (error) {
              ISpect.logger.error('Error reading plain text: $error');
            },
          );
          fileProcessed = true;
        }

        // 5. Handle file URLs (show path and try to read content)
        if (!fileProcessed && reader.canProvide(Formats.fileUri)) {
          reader.getValue<Uri>(
            Formats.fileUri,
            (value) {
              if (value != null && mounted) {
                setState(() {
                  _addWidgetToContent(_buildFileUriWidget(value));
                });
                // Try to read the actual file content if available
                _tryReadExternalFile(reader, value);
              }
            },
            onError: (error) {
              ISpect.logger.error('Error reading file URI: $error');
            },
          );
          fileProcessed = true;
        }

        // Show local data if available
        if (item.localData != null) {
          widgets.add(_buildLocalDataWidget(item.localData!));
        }
      }

      // Set initial content with headers and local data
      setState(() {
        _droppedWidgets.addAll(widgets);
        _updateContent();
      });
    } catch (e) {
      ISpect.logger.error('Error in _onPerformDrop: $e');
    }
  }

  void _addWidgetToContent(Widget widget) {
    _droppedWidgets.add(widget);
    _updateContent();
  }

  void _updateContent() {
    final delegate = SliverChildListDelegate(
      _droppedWidgets.toList(growable: false),
    );
    _content = CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(10),
          sliver: SliverList(delegate: delegate),
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

  bool _isDragOver = false;
  final List<Widget> _droppedWidgets = [];

  Widget _preview = const SizedBox();
  Widget _content = const Center(
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

  Widget _buildDropItemHeader(DropItem item) {
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

  Widget _buildFileUriWidget(Uri fileUri) {
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

  Widget _buildLocalDataWidget(Object localData) {
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

  void _handleTextFile(dynamic file) {
    // Always use stream approach since file.length might not be available
    final stream = file.getStream();
    final chunks = <Uint8List>[];

    stream.listen(
      (chunk) {
        chunks.add(chunk);
      },
      onDone: () {
        try {
          final combinedData = _combineChunks(chunks);
          final content = utf8.decode(combinedData);

          // Determine file type based on filename or content
          String fileName = 'unknown';
          String displayName = 'Text';
          String mimeType = 'text/plain';

          // First, try to detect JSON by content structure
          final trimmedContent = content.trim();
          bool isJsonContent = false;

          try {
            // Try to parse as JSON to verify it's valid JSON
            jsonDecode(trimmedContent);
            isJsonContent = true;
          } catch (e) {
            // Not valid JSON, check basic structure
            if ((trimmedContent.startsWith('{') &&
                    trimmedContent.endsWith('}')) ||
                (trimmedContent.startsWith('[') &&
                    trimmedContent.endsWith(']'))) {
              isJsonContent = true;
            }
          }

          if (file.fileName != null) {
            fileName = file.fileName!;
            if (fileName.toLowerCase().endsWith('.json')) {
              displayName = 'JSON';
              mimeType = 'application/json';
            } else if (fileName.toLowerCase().endsWith('.txt')) {
              // For .txt files, check if content is actually JSON
              if (isJsonContent) {
                displayName = 'JSON (from .txt file)';
                mimeType = 'application/json';
              } else {
                displayName = 'Text';
                mimeType = 'text/plain';
              }
            }
          } else {
            // No filename available, detect by content
            if (isJsonContent) {
              displayName = 'JSON';
              mimeType = 'application/json';
            }
          }

          if (mounted) {
            setState(() {
              _addWidgetToContent(
                _buildGenericTextFileWidget(
                  content,
                  file,
                  displayName,
                  mimeType,
                ),
              );
            });
          }
        } catch (e) {
          ISpect.logger.error('Error decoding text file stream: $e');
          if (mounted) {
            setState(() {
              _addWidgetToContent(
                _buildErrorWidget('Failed to decode file', e.toString()),
              );
            });
          }
        }
      },
      onError: (error) {
        ISpect.logger.error('Error reading text file stream: $error');
        if (mounted) {
          setState(() {
            _addWidgetToContent(
              _buildErrorWidget('Failed to read file', error.toString()),
            );
          });
        }
      },
    );
  }

  void _handleJsonFile(dynamic file) {
    ISpect.logger.info('Handling JSON file specifically');
    final stream = file.getStream();
    final chunks = <Uint8List>[];

    stream.listen(
      (chunk) {
        chunks.add(chunk);
      },
      onDone: () {
        try {
          final combinedData = _combineChunks(chunks);
          final content = utf8.decode(combinedData);

          // For JSON files, always treat as JSON
          if (mounted) {
            setState(() {
              _addWidgetToContent(
                _buildGenericTextFileWidget(
                  content,
                  file,
                  'JSON',
                  'application/json',
                ),
              );
            });
          }
        } catch (e) {
          ISpect.logger.error('Error decoding JSON file stream: $e');
          if (mounted) {
            setState(() {
              _addWidgetToContent(
                _buildErrorWidget('Failed to decode JSON file', e.toString()),
              );
            });
          }
        }
      },
      onError: (error) {
        ISpect.logger.error('Error reading JSON file stream: $error');
        if (mounted) {
          setState(() {
            _addWidgetToContent(
              _buildErrorWidget('Failed to read JSON file', error.toString()),
            );
          });
        }
      },
    );
  }

  void _handleHtmlFile(dynamic file) {
    ISpect.logger.info('Handling HTML file');
    final stream = file.getStream();
    final chunks = <Uint8List>[];

    stream.listen(
      (chunk) {
        chunks.add(chunk);
      },
      onDone: () {
        try {
          final combinedData = _combineChunks(chunks);
          final content = utf8.decode(combinedData);

          // Check if HTML content might actually contain JSON
          final trimmedContent = content.trim();
          String displayName = 'HTML';
          String mimeType = 'text/html';

          // Try to detect if this HTML actually contains JSON data
          if ((trimmedContent.startsWith('{') &&
                  trimmedContent.endsWith('}')) ||
              (trimmedContent.startsWith('[') &&
                  trimmedContent.endsWith(']'))) {
            try {
              jsonDecode(trimmedContent);
              displayName = 'JSON (from HTML format)';
              mimeType = 'application/json';
            } catch (e) {
              // Keep as HTML
            }
          }

          if (mounted) {
            setState(() {
              _addWidgetToContent(
                _buildGenericTextFileWidget(
                  content,
                  file,
                  displayName,
                  mimeType,
                ),
              );
            });
          }
        } catch (e) {
          ISpect.logger.error('Error decoding HTML file stream: $e');
          if (mounted) {
            setState(() {
              _addWidgetToContent(
                _buildErrorWidget('Failed to decode HTML file', e.toString()),
              );
            });
          }
        }
      },
      onError: (error) {
        ISpect.logger.error('Error reading HTML file stream: $error');
        if (mounted) {
          setState(() {
            _addWidgetToContent(
              _buildErrorWidget('Failed to read HTML file', error.toString()),
            );
          });
        }
      },
    );
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

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  int? _getFileLengthSafely(dynamic file) {
    try {
      // Try to access length property safely
      if (file.runtimeType.toString().contains('length')) {
        return file.length as int?;
      }
    } catch (e) {
      // Ignore errors and return null
    }
    return null;
  }

  void _tryReadExternalFile(dynamic reader, Uri fileUri) {
    // Try to read external file using different approaches
    final fileName = fileUri.pathSegments.isNotEmpty
        ? fileUri.pathSegments.last
        : 'unknown';
    final extension = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : '';

    // Only support .txt and .json files
    if (extension != 'txt' && extension != 'json') {
      _showExternalFileError(
        fileName,
        'Only .txt and .json files are supported',
      );
      return;
    }

    // Try reading as text file
    if (reader.canProvide(Formats.plainTextFile)) {
      reader.getFile(
        Formats.plainTextFile,
        (file) {
          _handleTextFile(file);
        },
        onError: (error) {
          ISpect.logger.error('Could not read external file as text: $error');
          _showExternalFileError(fileName, 'Could not read file content');
        },
      );
      return;
    }

    // Show information that file cannot be read
    _showExternalFileError(
      fileName,
      'File format not supported for content reading',
    );
  }

  void _tryReadWebFormat(dynamic reader, String format, DropItem item) {
    ISpect.logger.info('Attempting to read web format: $format');

    // Try different approaches to read web-specific formats
    try {
      // For web:file or web:entry formats, try different file formats
      if (reader.canProvide(Formats.json)) {
        reader.getFile(
          Formats.json,
          (file) {
            _handleJsonFile(file);
          },
          onError: (error) {
            ISpect.logger.error(
              'Error reading web format as JSON file: $error',
            );
            // Try as plain text file
            _tryWebFormatAsPlainText(reader, format);
          },
        );
        return;
      }

      // Try as plain text file
      if (reader.canProvide(Formats.plainTextFile)) {
        reader.getFile(
          Formats.plainTextFile,
          (file) {
            _handleTextFile(file);
          },
          onError: (error) {
            ISpect.logger.error(
              'Error reading web format as text file: $error',
            );
            _showWebFormatError(format, 'Could not read as text file');
          },
        );
        return;
      }

      // Try to read as plain text
      _tryWebFormatAsPlainText(reader, format);
    } catch (e) {
      ISpect.logger.error('Error in _tryReadWebFormat: $e');
      _showWebFormatError(format, 'Unexpected error: $e');
    }
  }

  void _tryReadMimeTypeFormat(dynamic reader, String mimeType, DropItem item) {
    ISpect.logger.info('Attempting to read MIME type: $mimeType');

    try {
      // For application/json or text/plain MIME types, try different formats
      if (mimeType == 'application/json' && reader.canProvide(Formats.json)) {
        // Try JSON format first for JSON MIME type
        reader.getFile(
          Formats.json,
          (file) {
            _handleJsonFile(file);
          },
          onError: (error) {
            ISpect.logger.error(
              'Error reading JSON MIME type as JSON file: $error',
            );
            // Fallback to plain text file
            _tryReadAsPlainTextFile(reader, mimeType);
          },
        );
        return;
      }

      // Try as plain text file for any MIME type
      if (reader.canProvide(Formats.plainTextFile)) {
        reader.getFile(
          Formats.plainTextFile,
          (file) {
            _handleTextFile(file);
          },
          onError: (error) {
            ISpect.logger.error('Error reading MIME type as file: $error');
            _showMimeTypeError(mimeType, 'Could not read file content');
          },
        );
        return;
      }

      // Try as plain text
      if (reader.canProvide(Formats.plainText)) {
        reader.getValue<String>(
          Formats.plainText,
          (value) {
            if (value != null && mounted) {
              final displayName = mimeType == 'application/json'
                  ? 'JSON'
                  : 'Text';
              final mockFile = _MockFile(
                content: value,
                fileName:
                    'mime_content.${mimeType == 'application/json' ? 'json' : 'txt'}',
              );
              setState(() {
                _addWidgetToContent(
                  _buildGenericTextFileWidget(
                    value,
                    mockFile,
                    displayName,
                    mimeType,
                  ),
                );
              });
            }
          },
          onError: (error) {
            ISpect.logger.error('Error reading MIME type as text: $error');
            _showMimeTypeError(mimeType, 'Could not read text content');
          },
        );
        return;
      }

      _showMimeTypeError(mimeType, 'MIME type not supported for reading');
    } catch (e) {
      ISpect.logger.error('Error in _tryReadMimeTypeFormat: $e');
      _showMimeTypeError(mimeType, 'Unexpected error: $e');
    }
  }

  void _showWebFormatError(String format, String error) {
    if (mounted) {
      setState(() {
        _addWidgetToContent(
          _buildFormatErrorWidget('Web Format', format, error),
        );
      });
    }
  }

  void _showMimeTypeError(String mimeType, String error) {
    if (mounted) {
      setState(() {
        _addWidgetToContent(
          _buildFormatErrorWidget('MIME Type', mimeType, error),
        );
      });
    }
  }

  void _tryReadAsPlainTextFile(dynamic reader, String mimeType) {
    if (reader.canProvide(Formats.plainTextFile)) {
      reader.getFile(
        Formats.plainTextFile,
        (file) {
          _handleTextFile(file);
        },
        onError: (error) {
          ISpect.logger.error('Error reading as plain text file: $error');
          _showMimeTypeError(mimeType, 'Could not read as text file');
        },
      );
    } else {
      _showMimeTypeError(mimeType, 'Plain text file format not available');
    }
  }

  void _tryWebFormatAsPlainText(dynamic reader, String format) {
    if (reader.canProvide(Formats.plainText)) {
      reader.getValue<String>(
        Formats.plainText,
        (value) {
          if (value != null && mounted) {
            final mockFile = _MockFile(
              content: value,
              fileName: 'web_format_content.txt',
            );
            setState(() {
              _addWidgetToContent(
                _buildGenericTextFileWidget(
                  value,
                  mockFile,
                  'Web Content',
                  'text/plain',
                ),
              );
            });
          }
        },
        onError: (error) {
          ISpect.logger.error('Error reading web format as plain text: $error');
          _showWebFormatError(format, 'Could not read as plain text');
        },
      );
    } else {
      _showWebFormatError(format, 'Format not supported for content reading');
    }
  }

  Widget _buildFormatErrorWidget(String type, String format, String error) {
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

  Widget _buildErrorWidget(String title, String error) {
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

  void _showExternalFileError(String fileName, String error) {
    if (mounted) {
      setState(() {
        _addWidgetToContent(_buildExternalFileErrorWidget(fileName, error));
      });
    }
  }

  Widget _buildExternalFileErrorWidget(String fileName, String error) {
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

  Widget _buildGenericTextFileWidget(
    String content,
    dynamic file,
    String displayName,
    String mimeType,
  ) {
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
                MaterialPageRoute(
                  builder: (context) => JsonScreen(
                    data: {
                      'display_name': displayName,
                      'mime_type': mimeType,
                      'file_name': file.fileName ?? 'unknown',
                      'size': fileLength != null
                          ? _formatFileSize(fileLength)
                          : 'unknown',
                      'fileName': file ?? 'unknown',
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

  void _showFileOptionsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
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
                  _showPasteDialog();
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.content_paste),
                title: const Text('Pick Files'),
                subtitle: const Text(
                  'Select .txt or .json files from your device',
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _showFilePicker();
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
      },
    );
  }

  void _showFilePicker() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['txt', 'json'],
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      for (final PlatformFile file in result.files) {
        if (!mounted) return;

        // Validate file extension
        final String fileName = file.name.toLowerCase();
        if (!fileName.endsWith('.txt') && !fileName.endsWith('.json')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Unsupported file type: ${file.name}'),
              backgroundColor: Colors.orange,
            ),
          );
          continue;
        }

        // Check file size (limit to 10MB)
        if (file.size > 10 * 1024 * 1024) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File too large: ${file.name} (max 10MB)'),
              backgroundColor: Colors.red,
            ),
          );
          continue;
        }

        // Read file content
        String? content;
        if (kIsWeb) {
          // For web platform, use bytes
          if (file.bytes != null) {
            try {
              content = utf8.decode(file.bytes!);
            } catch (e) {
              ISpect.logger.error('Error decoding file bytes: $e');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error reading file: ${file.name}'),
                  backgroundColor: Colors.red,
                ),
              );
              continue;
            }
          }
        } else {
          // For mobile platforms, use file path
          if (file.path != null) {
            try {
              final File fileHandle = File(file.path!);
              content = await fileHandle.readAsString();
            } catch (e) {
              ISpect.logger.error('Error reading file from path: $e');
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error reading file: ${file.name}'),
                  backgroundColor: Colors.red,
                ),
              );
              continue;
            }
          }
        }

        if (content == null || content.isEmpty) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Empty or unreadable file: ${file.name}'),
              backgroundColor: Colors.orange,
            ),
          );
          continue;
        }

        // Determine file type and display properties
        String displayName = 'Text';
        String mimeType = 'text/plain';

        if (fileName.endsWith('.json')) {
          displayName = 'JSON';
          mimeType = 'application/json';

          // Validate JSON structure
          try {
            jsonDecode(content);
          } catch (e) {
            // Still process as JSON but show warning
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Warning: ${file.name} contains invalid JSON'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        } else {
          // For .txt files, try to detect if content is actually JSON
          final String trimmedContent = content.trim();
          if ((trimmedContent.startsWith('{') &&
                  trimmedContent.endsWith('}')) ||
              (trimmedContent.startsWith('[') &&
                  trimmedContent.endsWith(']'))) {
            try {
              jsonDecode(trimmedContent);
              displayName = 'JSON (from .txt file)';
              mimeType = 'application/json';
            } catch (e) {
              // Keep as text file
            }
          }
        }

        // Ensure content is not null (we already checked this above)
        final String finalContent = content;

        // Create mock file object with platform file information
        final mockFile = _MockFileWithPlatformFile(
          content: finalContent,
          fileName: file.name,
          size: file.size,
          platformFile: file,
        );

        // Add the processed file to the drop zone
        setState(() {
          _addWidgetToContent(
            _buildGenericTextFileWidget(
              finalContent,
              mockFile,
              displayName,
              mimeType,
            ),
          );
        });

        // Show success message
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Loaded file: ${file.name}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ISpect.logger.error('Error in file picker: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening file picker: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPasteDialog() {
    final TextEditingController controller = TextEditingController();
    String selectedFormat = 'auto';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                          value: selectedFormat,
                          items: const [
                            DropdownMenuItem(
                              value: 'auto',
                              child: Text('Auto-detect'),
                            ),
                            DropdownMenuItem(
                              value: 'json',
                              child: Text('JSON'),
                            ),
                            DropdownMenuItem(
                              value: 'text',
                              child: Text('Plain Text'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedFormat = value!;
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
                        controller: controller,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText:
                              'Paste your .txt or .json file content here...',
                        ),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
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
                    if (controller.text.trim().isNotEmpty) {
                      Navigator.of(context).pop();
                      _processPastedContent(controller.text, selectedFormat);
                    }
                  },
                  child: const Text('Process'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _processPastedContent(String content, String format) {
    // Auto-detect format if needed
    String detectedFormat = format;
    String displayName = 'Pasted Content';
    String mimeType = 'text/plain';

    if (format == 'auto') {
      final trimmedContent = content.trim();
      if ((trimmedContent.startsWith('{') && trimmedContent.endsWith('}')) ||
          (trimmedContent.startsWith('[') && trimmedContent.endsWith(']'))) {
        detectedFormat = 'json';
      }
    }

    // Set display name and MIME type based on format
    switch (detectedFormat) {
      case 'json':
        displayName = 'JSON';
        mimeType = 'application/json';
        break;
      default:
        displayName = 'Text';
        mimeType = 'text/plain';
    }

    // Create a mock file object
    final mockFile = _MockFile(
      content: content,
      fileName:
          'pasted_content.${detectedFormat == 'auto' || detectedFormat == 'text' ? 'txt' : detectedFormat}',
    );

    setState(() {
      _addWidgetToContent(
        _buildGenericTextFileWidget(content, mockFile, displayName, mimeType),
      );
    });
  }
}

class _MockFile {
  final String content;
  final String? fileName;

  _MockFile({required this.content, this.fileName});
}

class _MockFileWithPlatformFile {
  final String content;
  final String? fileName;
  final int? size;
  final PlatformFile platformFile;

  _MockFileWithPlatformFile({
    required this.content,
    this.fileName,
    this.size,
    required this.platformFile,
  });

  // Getter for compatibility with existing code
  int? get length => size;
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
        style: const TextStyle(fontSize: 11.0),
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
