import 'dart:convert';
import 'dart:ui' as ui;

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

void main() async {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Super Drag and Drop Example'),
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
  const HomeLayout({
    super.key,
    required this.draggable,
    required this.dropZone,
  });

  final List<Widget> draggable;
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
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    direction: Axis.horizontal,
                    runSpacing: 8,
                    spacing: 10,
                    children: draggable,
                  ),
                ),
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
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: IntrinsicWidth(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 8,
                      children: draggable.toList(growable: false),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0).copyWith(right: 0),
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
      'name': 'Super Drag and Drop Example',
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
      appBar: AppBar(title: Text(widget.title)),
      body: HomeLayout(
        draggable: [
          DragableWidget(
            name: 'Text',
            color: Colors.red,
            dragItemProvider: textDragItem,
          ),
          DragableWidget(
            name: 'Image',
            color: Colors.green,
            dragItemProvider: imageDragItem,
          ),
          DragableWidget(
            name: 'Lazy Image',
            color: Colors.blue,
            dragItemProvider: lazyImageDragItem,
          ),
          DragableWidget(
            name: 'Virtual File',
            color: Colors.amber.shade700,
            dragItemProvider: virtualFileDragItem,
          ),
          DragableWidget(
            name: 'Text File',
            color: Colors.teal,
            dragItemProvider: fileDragItem,
          ),
          DragableWidget(
            name: 'JSON Data',
            color: Colors.deepPurple,
            dragItemProvider: jsonDragItem,
          ),
          DragableWidget(
            name: 'Multiple',
            color: Colors.pink,
            dragItemProvider: multipleRepresentationsDragItem,
          ),
        ],
        dropZone: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blueGrey.shade200),
            borderRadius: BorderRadius.circular(14),
          ),
          child: _DropZone(),
        ),
      ),
    );
  }
}

class _DropZone extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _DropZoneState();
}

class _DropZoneState extends State<_DropZone> {
  @override
  Widget build(BuildContext context) {
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
              children: [
                const Icon(Icons.folder_open),
                const SizedBox(width: 8),
                const Text(
                  'Drop Zone',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (_droppedWidgets.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: _clearDroppedItems,
                    icon: const Icon(Icons.clear, size: 16),
                    label: const Text('Clear'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade100,
                      foregroundColor: Colors.red.shade700,
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
    print('Drop over: ${event.session.items.length} items');
    setState(() {
      _isDragOver = true;
      _preview = Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          color: Colors.black.withOpacity(0.2),
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
    if (!mounted) {
      return;
    }

    final widgets = <Widget>[];

    for (final item in event.session.items) {
      final reader = item.dataReader!;

      // Process each format the item can provide
      widgets.add(_buildDropItemHeader(item));

      // Handle text data
      if (reader.canProvide(Formats.plainText)) {
        reader.getValue<String>(
          Formats.plainText,
          (value) {
            if (value != null && mounted) {
              setState(() {
                _addWidgetToContent(_buildTextWidget('Plain Text', value));
              });
            }
          },
          onError: (error) {
            print('Error reading plain text: $error');
          },
        );
      }

      // Handle HTML text
      if (reader.canProvide(Formats.htmlText)) {
        reader.getValue<String>(
          Formats.htmlText,
          (value) {
            if (value != null && mounted) {
              setState(() {
                _addWidgetToContent(_buildTextWidget('HTML Text', value));
              });
            }
          },
          onError: (error) {
            print('Error reading HTML text: $error');
          },
        );
      }

      // Handle URI/URL
      if (reader.canProvide(Formats.uri)) {
        reader.getValue<NamedUri>(
          Formats.uri,
          (value) {
            if (value != null && mounted) {
              setState(() {
                _addWidgetToContent(_buildUriWidget(value));
              });
            }
          },
          onError: (error) {
            print('Error reading URI: $error');
          },
        );
      }

      // Handle file URLs (file paths)
      if (reader.canProvide(Formats.fileUri)) {
        reader.getValue<Uri>(
          Formats.fileUri,
          (value) {
            if (value != null && mounted) {
              setState(() {
                _addWidgetToContent(_buildFileUriWidget(value));
              });
            }
          },
          onError: (error) {
            print('Error reading file URI: $error');
          },
        );
      }

      // Handle PNG images
      if (reader.canProvide(Formats.png)) {
        reader.getFile(
          Formats.png,
          (file) {
            _handleImageFile(file, 'PNG Image');
          },
          onError: (error) {
            print('Error reading PNG: $error');
          },
        );
      }

      // Handle JPEG images
      if (reader.canProvide(Formats.jpeg)) {
        reader.getFile(
          Formats.jpeg,
          (file) {
            _handleImageFile(file, 'JPEG Image');
          },
          onError: (error) {
            print('Error reading JPEG: $error');
          },
        );
      }

      // Handle generic files
      if (reader.canProvide(Formats.plainTextFile)) {
        reader.getFile(
          Formats.plainTextFile,
          (file) {
            _handleTextFile(file);
          },
          onError: (error) {
            print('Error reading text file: $error');
          },
        );
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

  Widget _buildTextWidget(String type, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            type,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade800,
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(content, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildUriWidget(NamedUri namedUri) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'URI/Link',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.purple.shade800,
            ),
          ),
          const SizedBox(height: 8),
          if (namedUri.name != null) ...[
            Text('Name: ${namedUri.name}'),
            const SizedBox(height: 4),
          ],
          SelectableText(
            'URL: ${namedUri.uri.toString()}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue.shade600,
              decoration: TextDecoration.underline,
            ),
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

  void _handleImageFile(dynamic file, String imageType) {
    // For small images, read all data into memory
    if (file.length != null && file.length! < 10 * 1024 * 1024) {
      // 10MB limit
      final imageData = file.readAll();
      if (mounted) {
        setState(() {
          _addWidgetToContent(_buildImageWidget(imageType, imageData, file));
        });
      }
    } else {
      // For large images, use stream
      _handleImageStream(file, imageType);
    }
  }

  Widget _buildImageWidget(
    String imageType,
    Uint8List imageData,
    dynamic file,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.indigo.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            imageType,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.indigo.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text('Size: ${_formatFileSize(imageData.length)}'),
          if (file.fileName != null) ...[
            const SizedBox(height: 4),
            Text('File Name: ${file.fileName}'),
          ],
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                imageData,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 100,
                  color: Colors.red.shade100,
                  child: Center(child: Text('Failed to load image: $error')),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleImageStream(dynamic file, String imageType) {
    final stream = file.getStream();
    final chunks = <Uint8List>[];

    stream.listen(
      (chunk) {
        chunks.add(chunk);
      },
      onDone: () {
        if (mounted) {
          final combinedData = _combineChunks(chunks);
          setState(() {
            _addWidgetToContent(
              _buildImageWidget(imageType, combinedData, file),
            );
          });
        }
      },
      onError: (error) {
        print('Error reading image stream: $error');
      },
    );
  }

  void _handleTextFile(dynamic file) {
    if (file.length != null && file.length! < 1024 * 1024) {
      // 1MB limit for text files
      try {
        final textData = file.readAll();
        final content = utf8.decode(textData);

        if (mounted) {
          setState(() {
            _addWidgetToContent(_buildTextFileWidget(content, file));
          });
        }
      } catch (e) {
        print('Error decoding text file: $e');
      }
    } else {
      _handleTextFileStream(file);
    }
  }

  Widget _buildTextFileWidget(String content, dynamic file) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.teal.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Text File',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.teal.shade800,
            ),
          ),
          const SizedBox(height: 8),
          if (file.fileName != null) ...[
            Text('File Name: ${file.fileName}'),
            const SizedBox(height: 4),
          ],
          if (file.length != null) ...[
            Text('File Size: ${_formatFileSize(file.length!)}'),
            const SizedBox(height: 8),
          ],
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            child: SingleChildScrollView(
              child: SelectableText(
                content,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleTextFileStream(dynamic file) {
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

          if (mounted) {
            setState(() {
              _addWidgetToContent(_buildTextFileWidget(content, file));
            });
          }
        } catch (e) {
          print('Error decoding text file stream: $e');
        }
      },
      onError: (error) {
        print('Error reading text file stream: $error');
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
