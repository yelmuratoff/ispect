import 'package:flutter/widgets.dart';
import 'package:ispect/src/features/json_viewer/models/node_view_model.dart';

/// How a JSON viewer presents a document on open: which sections it offers
/// as shortcuts and which subtrees start folded.
///
/// Paths are full key paths from the document root, so a key with the same
/// name deeper in the data never matches. Paths that are absent from the
/// document are ignored.
@immutable
final class JsonOutline {
  const JsonOutline({this.landmarks = const [], this.foldedPaths = const []});

  /// Sections offered as shortcuts, in display order.
  final List<JsonLandmark> landmarks;

  /// Subtrees collapsed when the document opens.
  final List<List<String>> foldedPaths;
}

/// A section of a JSON document the viewer can jump to.
@immutable
final class JsonLandmark {
  const JsonLandmark({
    required this.id,
    required this.label,
    required this.icon,
    required this.paths,
    this.showsCount = false,
  });

  /// Stable identifier, independent of the localized [label].
  final String id;

  final String Function(BuildContext context) label;

  final IconData icon;

  /// Candidate key paths in priority order; the first one present wins.
  final List<List<String>> paths;

  final bool showsCount;
}

typedef ResolvedJsonLandmark = ({
  JsonLandmark landmark,
  NodeViewModelState node,
});
