// Cross-platform indirection for reading process RSS. The `dart:io`
// implementation runs on mobile/desktop; the stub returns null on web.
export 'memory_stats_stub.dart' if (dart.library.io) 'memory_stats_io.dart';
