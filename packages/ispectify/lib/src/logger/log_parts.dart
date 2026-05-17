/// Small utility for building multi-line log texts without leading blank lines.
String joinLogParts(List<String?> parts) {
  final buffer = StringBuffer();

  for (final part in parts) {
    if (part == null || part.isEmpty) continue;
    if (buffer.isNotEmpty) buffer.write('\n');
    buffer.write(part);
  }

  return buffer.toString();
}
