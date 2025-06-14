// ignore_for_file: avoid_dynamic_calls

import 'package:flutter/rendering.dart';
import 'package:ispect/src/features/inspector/src/widgets/inspector/box_info.dart';

/// Recreates Flutter's diagnostic information for release mode
///
/// This class provides functionality similar to toDiagnosticsNode().toStringDeep()
/// but works in both debug and release modes by manually extracting properties
class DiagnosticsRecreator {
  const DiagnosticsRecreator._();

  /// Recreates the deep string representation similar to toStringDeep()
  ///
  /// - Parameters:
  ///   - renderObject: The RenderObject to analyze
  ///   - prefix: Indentation prefix for nested objects
  ///   - maxDepth: Maximum depth to traverse (prevents infinite loops)
  ///   - currentDepth: Current traversal depth
  /// - Return: Multi-line string with detailed diagnostic information
  static String recreateToStringDeep(
    RenderObject renderObject, {
    String prefix = '',
    int maxDepth = 10,
    int currentDepth = 0,
  }) {
    if (currentDepth >= maxDepth) {
      return '$prefix... (max depth reached)\n';
    }

    final buffer = StringBuffer()

      // Main object description
      ..writeln('$prefix${_getObjectDescription(renderObject)}');

    // Add properties
    final properties = _extractProperties(renderObject);
    for (final property in properties) {
      buffer.writeln('$prefix  $property');
    }

    // Recursively process children
    renderObject.visitChildren((child) {
      buffer.write(
        recreateToStringDeep(
          child,
          prefix: '$prefix  ',
          maxDepth: maxDepth,
          currentDepth: currentDepth + 1,
        ),
      );
    });

    return buffer.toString();
  }

  /// Gets the main object description (type and key info)
  static String _getObjectDescription(RenderObject renderObject) {
    final type = renderObject.runtimeType.toString();

    // Try to get additional identifying information
    final extras = <String>[];

    if (renderObject is RenderBox && renderObject.hasSize) {
      final size = renderObject.size;
      extras.add(
        '${size.width.toStringAsFixed(1)} × ${size.height.toStringAsFixed(1)}',
      );
    }

    if (renderObject is RenderParagraph) {
      // Get text information if available
      try {
        final text = renderObject.text;
        if (text.toPlainText().isNotEmpty) {
          final plainText = text.toPlainText();
          final truncated = plainText.length > 30
              ? '${plainText.substring(0, 30)}...'
              : plainText;
          extras.add('"$truncated"');
        }
      } catch (e) {
        // Ignore errors accessing text
      }
    }

    final extrasStr = extras.isNotEmpty ? ' (${extras.join(', ')})' : '';
    return '$type$extrasStr';
  }

  /// Extracts all relevant properties from a RenderObject
  static List<String> _extractProperties(RenderObject renderObject) {
    final properties = <String>[..._extractBasicProperties(renderObject)];

    // Type-specific properties
    if (renderObject is RenderBox) {
      properties.addAll(_extractRenderBoxProperties(renderObject));
    }

    if (renderObject is RenderDecoratedBox) {
      properties.addAll(_extractDecoratedBoxProperties(renderObject));
    }

    if (renderObject is RenderParagraph) {
      properties.addAll(_extractParagraphProperties(renderObject));
    }

    if (renderObject is RenderImage) {
      properties.addAll(_extractImageProperties(renderObject));
    }

    if (renderObject is RenderFlex) {
      properties.addAll(_extractFlexProperties(renderObject));
    }

    if (renderObject is RenderPadding) {
      properties.addAll(_extractPaddingProperties(renderObject));
    }

    if (renderObject is RenderStack) {
      properties.addAll(_extractStackProperties(renderObject));
    }

    if (renderObject is RenderTransform) {
      properties.addAll(_extractTransformProperties(renderObject));
    }

    if (renderObject is RenderOpacity) {
      properties.addAll(_extractOpacityProperties(renderObject));
    }

    if (renderObject is RenderClipRect) {
      properties.addAll(_extractClipProperties(renderObject));
    }

    return properties;
  }

  /// Extracts basic properties common to all RenderObjects
  static List<String> _extractBasicProperties(RenderObject renderObject) {
    final properties = <String>['attached: ${renderObject.attached}'];

    // Owner information
    if (renderObject.owner != null) {
      properties.add('owner: ${renderObject.owner.runtimeType}');
    }

    // Parent information and ParentData details
    if (renderObject.parent != null) {
      properties
          .add('parentData: ${renderObject.parentData?.runtimeType ?? 'null'}');

      // Extract specific ParentData information
      final parentData = renderObject.parentData;
      if (parentData is StackParentData) {
        final positionInfo = <String>[];
        if (parentData.left != null) {
          positionInfo.add('left: ${parentData.left}');
        }
        if (parentData.top != null) positionInfo.add('top: ${parentData.top}');
        if (parentData.right != null) {
          positionInfo.add('right: ${parentData.right}');
        }
        if (parentData.bottom != null) {
          positionInfo.add('bottom: ${parentData.bottom}');
        }
        if (parentData.width != null) {
          positionInfo.add('width: ${parentData.width}');
        }
        if (parentData.height != null) {
          positionInfo.add('height: ${parentData.height}');
        }

        if (positionInfo.isNotEmpty) {
          properties.add('position: ${positionInfo.join(', ')}');
        }
        properties.add('isPositioned: ${parentData.isPositioned}');
      } else if (parentData is FlexParentData) {
        if (parentData.flex != null) {
          properties.add('flex: ${parentData.flex}');
        }
        if (parentData.fit != null) {
          properties.add('fit: ${parentData.fit}');
        }
      }
    }

    // Depth in render tree
    properties.add('depth: ${renderObject.depth}');

    return properties;
  }

  /// Extracts RenderBox-specific properties
  static List<String> _extractRenderBoxProperties(RenderBox renderBox) {
    final properties = <String>['hasSize: ${renderBox.hasSize}'];

    if (renderBox.hasSize) {
      final size = renderBox.size;
      properties.add(
        'size: Size(${size.width.toStringAsFixed(1)}, ${size.height.toStringAsFixed(1)})',
      );
    }

    // Constraints
    try {
      properties.add('constraints: ${renderBox.constraints}');
    } catch (e) {
      properties.add('constraints: <not available>');
    }

    // Position (if attached)
    if (renderBox.attached && renderBox.hasSize) {
      try {
        final position = renderBox.localToGlobal(Offset.zero);
        properties.add(
          'globalPosition: Offset(${position.dx.toStringAsFixed(1)}, ${position.dy.toStringAsFixed(1)})',
        );
      } catch (e) {
        properties.add('globalPosition: <unable to calculate>');
      }
    }

    // Semantic properties
    properties.add('semanticBounds: ${renderBox.semanticBounds}');

    return properties;
  }

  /// Extracts DecoratedBox-specific properties
  static List<String> _extractDecoratedBoxProperties(
    RenderDecoratedBox decoratedBox,
  ) {
    final properties = <String>[];
    final decoration = decoratedBox.decoration;

    properties.add('decoration: ${decoration.runtimeType}');

    if (decoration is BoxDecoration) {
      // Color
      if (decoration.color != null) {
        properties.add('color: ${decoration.color}');
      }

      // Border
      if (decoration.border != null) {
        properties.add('border: ${decoration.border}');
      }

      // Border radius
      if (decoration.borderRadius != null) {
        properties.add('borderRadius: ${decoration.borderRadius}');
      }

      // Box shadow
      if (decoration.boxShadow != null && decoration.boxShadow!.isNotEmpty) {
        properties.add('boxShadow: ${decoration.boxShadow!.length} shadow(s)');
      }

      // Gradient
      if (decoration.gradient != null) {
        properties.add('gradient: ${decoration.gradient.runtimeType}');
      }

      // Background image
      if (decoration.image != null) {
        properties
            .add('backgroundImage: ${decoration.image!.image.runtimeType}');
      }

      // Shape
      properties.add('shape: ${decoration.shape}');
    }

    // Position
    properties.add('position: ${decoratedBox.position}');

    return properties;
  }

  /// Extracts Paragraph-specific properties
  static List<String> _extractParagraphProperties(RenderParagraph paragraph) {
    final properties = <String>[];

    try {
      final text = paragraph.text;
      properties.add('text: "${text.toPlainText()}"');

      // Text style information
      if (text.style != null) {
        final style = text.style!;
        if (style.fontSize != null) {
          properties.add('fontSize: ${style.fontSize}');
        }
        if (style.color != null) {
          properties.add('textColor: ${style.color}');
        }
        if (style.fontFamily != null) {
          properties.add('fontFamily: ${style.fontFamily}');
        }
        if (style.fontWeight != null) {
          properties.add('fontWeight: ${style.fontWeight}');
        }
      }

      properties
        ..add('textAlign: ${paragraph.textAlign}')
        ..add('textDirection: ${paragraph.textDirection}')
        ..add('maxLines: ${paragraph.maxLines ?? 'null'}')
        ..add('overflow: ${paragraph.overflow}');
    } catch (e) {
      properties.add('text: <unable to access>');
    }

    return properties;
  }

  /// Extracts Image-specific properties
  static List<String> _extractImageProperties(RenderImage image) {
    final properties = <String>[];

    if (image.image != null) {
      properties.add('image: ${image.image.runtimeType}');
    }

    properties
      ..add('fit: ${image.fit}')
      ..add('alignment: ${image.alignment}')
      ..add('repeat: ${image.repeat}');

    if (image.color != null) {
      properties.add('color: ${image.color}');
    }

    if (image.colorBlendMode != null) {
      properties.add('colorBlendMode: ${image.colorBlendMode}');
    }

    return properties;
  }

  /// Extracts Flex-specific properties
  static List<String> _extractFlexProperties(RenderFlex flex) {
    final properties = <String>[
      'direction: ${flex.direction}',
      'mainAxisAlignment: ${flex.mainAxisAlignment}',
      'crossAxisAlignment: ${flex.crossAxisAlignment}',
      'mainAxisSize: ${flex.mainAxisSize}',
      'textDirection: ${flex.textDirection}',
      'verticalDirection: ${flex.verticalDirection}',
    ];

    return properties;
  }

  /// Extracts Padding-specific properties
  static List<String> _extractPaddingProperties(RenderPadding padding) {
    final properties = <String>[
      'padding: ${padding.padding}',
      'textDirection: ${padding.textDirection}',
    ];

    return properties;
  }

  /// Extracts Stack-specific properties
  static List<String> _extractStackProperties(RenderStack stack) {
    final properties = <String>[
      'alignment: ${stack.alignment}',
      'textDirection: ${stack.textDirection}',
      'fit: ${stack.fit}',
      'clipBehavior: ${stack.clipBehavior}',
    ];

    // Analyze positioned children
    var positionedCount = 0;
    stack.visitChildren((child) {
      if (child.parentData is StackParentData) {
        final parentData = child.parentData! as StackParentData;
        if (parentData.isPositioned) {
          positionedCount++;
        }
      }
    });

    properties.add('positionedChildren: $positionedCount');

    return properties;
  }

  /// Extracts Transform-specific properties
  static List<String> _extractTransformProperties(
    RenderTransform renderTransform,
  ) {
    final properties = <String>[
      'transform: $renderTransform',
      'alignment: ${renderTransform.alignment}',
      'textDirection: ${renderTransform.textDirection}',
      'transformHitTests: ${renderTransform.transformHitTests}',
    ];

    return properties;
  }

  /// Extracts Opacity-specific properties
  static List<String> _extractOpacityProperties(RenderOpacity opacity) {
    final properties = <String>[
      'opacity: ${opacity.opacity.toStringAsFixed(2)}',
      'alwaysIncludeSemantics: ${opacity.alwaysIncludeSemantics}',
    ];

    return properties;
  }

  /// Extracts Clip-specific properties
  static List<String> _extractClipProperties(RenderClipRect clip) {
    final properties = <String>[];

    if (clip.clipper != null) {
      properties.add('clipper: ${clip.clipper.runtimeType}');
    }
    properties.add('clipBehavior: ${clip.clipBehavior}');

    return properties;
  }

  /// Convenience method to get diagnostics for a BoxInfo target
  static String getDiagnosticsForBoxInfo(BoxInfo boxInfo) =>
      recreateToStringDeep(boxInfo.targetRenderBox);

  /// Gets a structured map of all properties for programmatic access
  static Map<String, dynamic> getStructuredDiagnostics(
    RenderObject renderObject,
  ) {
    final diagnostics = <String, dynamic>{};

    // Basic info
    diagnostics['type'] = renderObject.runtimeType.toString();
    diagnostics['attached'] = renderObject.attached;
    diagnostics['depth'] = renderObject.depth;

    // Widget properties
    final widgetProps = <String, dynamic>{};
    if (renderObject is RenderBox && renderObject.hasSize) {
      widgetProps['size'] = {
        'width': renderObject.size.width,
        'height': renderObject.size.height,
      };
      widgetProps['constraints'] = renderObject.constraints.toString();
    }
    diagnostics['widgetProperties'] = widgetProps;

    // Layout properties
    final layoutProps = <String, dynamic>{};
    if (renderObject is RenderBox &&
        renderObject.attached &&
        renderObject.hasSize) {
      try {
        final position = renderObject.localToGlobal(Offset.zero);
        layoutProps['globalPosition'] = {
          'x': position.dx,
          'y': position.dy,
        };
      } catch (e) {
        layoutProps['globalPosition'] = null;
      }
    }
    diagnostics['layoutProperties'] = layoutProps;

    // Render properties
    final renderProps = <String, dynamic>{};
    renderProps['hasSize'] =
        // ignore: avoid_bool_literals_in_conditional_expressions
        renderObject is RenderBox ? renderObject.hasSize : false;
    try {
      renderProps['needsLayout'] = renderObject.debugNeedsLayout;
      renderProps['needsPaint'] = renderObject.debugNeedsPaint;
    } catch (e) {
      // Debug properties might not be available in release mode
      renderProps['needsLayout'] = false;
      renderProps['needsPaint'] = false;
    }
    diagnostics['renderProperties'] = renderProps;

    return diagnostics;
  }
}

// Extension for BoxInfo to integrate with DiagnosticsRecreator
extension BoxInfoDiagnostics on BoxInfo {
  /// Gets the deep diagnostic string for the target render box
  String toStringDeep({int maxDepth = 10}) =>
      DiagnosticsRecreator.recreateToStringDeep(
        targetRenderBox,
        maxDepth: maxDepth,
      );

  /// Gets structured diagnostics for the target render box
  Map<String, dynamic> getStructuredDiagnostics() =>
      DiagnosticsRecreator.getStructuredDiagnostics(targetRenderBox);

  /// Gets enhanced properties including diagnostic information
  Map<String, String> getEnhancedProperties() {
    final properties = getProperties();

    // Add diagnostic information
    final diagnosticProperties =
        DiagnosticsRecreator._extractProperties(targetRenderBox);
    for (var i = 0; i < diagnosticProperties.length; i++) {
      properties['diagnostic_$i'] = diagnosticProperties[i];
    }

    return properties;
  }

  /// Gets a comprehensive summary including diagnostic info
  String getComprehensiveSummary() {
    final basicSummary = getSummary();
    final diagnostics = getStructuredDiagnostics();

    final buffer = StringBuffer(basicSummary);

    // Add layout info if available
    final layoutProps = diagnostics['layoutProperties'] as Map<String, dynamic>;
    if (layoutProps['globalPosition'] != null) {
      final pos = layoutProps['globalPosition'] as Map<String, dynamic>;
      buffer.write(
        ' at (${pos['x']?.toStringAsFixed(1)}, ${pos['y']?.toStringAsFixed(1)})',
      );
    }

    // Add render state
    final renderProps = diagnostics['renderProperties'] as Map<String, dynamic>;
    if (renderProps['needsLayout'] == true ||
        renderProps['needsPaint'] == true) {
      final states = <String>[];
      if (renderProps['needsLayout'] == true) states.add('needs layout');
      if (renderProps['needsPaint'] == true) states.add('needs paint');
      buffer.write(' [${states.join(', ')}]');
    }

    return buffer.toString();
  }
}
