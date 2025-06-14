// ignore_for_file: avoid_dynamic_calls

import 'package:flutter/rendering.dart';
import 'package:ispect/src/features/inspector/src/widgets/inspector/box_info.dart';

class DiagnosticsRecreator {
  const DiagnosticsRecreator._();

  static String recreateToStringDeep(
    RenderObject renderObject, {
    String prefix = '-',
    int maxDepth = 10,
    int currentDepth = 1,
  }) {
    if (currentDepth >= maxDepth) {
      return '$prefix... (max depth reached)\n';
    }

    final buffer = StringBuffer()

      // Main object description
      ..writeln('$prefix ${_getObjectDescription(renderObject)}');

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
          prefix: prefix * currentDepth,
          maxDepth: maxDepth,
          currentDepth: currentDepth + 1,
        ),
      );
    });

    return buffer.toString();
  }

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

  static List<String> _extractPaddingProperties(RenderPadding padding) {
    final properties = <String>[
      'padding: ${padding.padding}',
      'textDirection: ${padding.textDirection}',
    ];

    return properties;
  }

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

  static List<String> _extractOpacityProperties(RenderOpacity opacity) {
    final properties = <String>[
      'opacity: ${opacity.opacity.toStringAsFixed(2)}',
      'alwaysIncludeSemantics: ${opacity.alwaysIncludeSemantics}',
    ];

    return properties;
  }

  static List<String> _extractClipProperties(RenderClipRect clip) {
    final properties = <String>[];

    if (clip.clipper != null) {
      properties.add('clipper: ${clip.clipper.runtimeType}');
    }
    properties.add('clipBehavior: ${clip.clipBehavior}');

    return properties;
  }

  static String getDiagnosticsForBoxInfo(BoxInfo boxInfo) =>
      recreateToStringDeep(boxInfo.targetRenderBox);

  static Map<String, dynamic> getNestedDiagnosticsForBoxInfo(BoxInfo boxInfo) =>
      getNestedDiagnosticsMap(boxInfo.targetRenderBox);

  static Map<String, dynamic> getNestedDiagnosticsMap(
    RenderObject renderObject, {
    int maxDepth = 10,
    int currentDepth = 1,
  }) {
    if (currentDepth >= maxDepth) {
      return {
        'type': renderObject.runtimeType.toString(),
        'maxDepthReached': true,
        'currentDepth': currentDepth,
      };
    }

    final diagnostics = <String, dynamic>{};

    // Basic object information
    diagnostics['type'] = renderObject.runtimeType.toString();
    diagnostics['description'] = _getObjectDescription(renderObject);
    diagnostics['depth'] = currentDepth;
    diagnostics['attached'] = renderObject.attached;

    // Extract all properties as structured data
    final properties = _extractProperties(renderObject);
    final structuredProperties = <String, dynamic>{};

    for (final property in properties) {
      final parts = property.split(': ');
      if (parts.length >= 2) {
        final key = parts[0].trim();
        final value = parts.sublist(1).join(': ').trim();
        structuredProperties[key] = _parsePropertyValue(value);
      } else {
        structuredProperties[property] = true;
      }
    }
    diagnostics['properties'] = structuredProperties;

    // Type-specific structured data
    diagnostics['typeSpecificData'] = _getTypeSpecificData(renderObject);

    // Children
    final children = <Map<String, dynamic>>[];
    renderObject.visitChildren((child) {
      children.add(
        getNestedDiagnosticsMap(
          child,
          maxDepth: maxDepth,
          currentDepth: currentDepth + 1,
        ),
      );
    });

    if (children.isNotEmpty) {
      diagnostics['children'] = children;
      diagnostics['childrenCount'] = children.length;
    }

    return diagnostics;
  }

  static dynamic _parsePropertyValue(String value) {
    // Remove common prefixes and suffixes
    final cleanValue = value.trim();

    // Try to parse as boolean
    if (cleanValue == 'true') return true;
    if (cleanValue == 'false') return false;
    if (cleanValue == 'null') return null;

    // Try to parse as number
    final numValue = double.tryParse(cleanValue);
    if (numValue != null) return numValue;

    // Try to parse Size
    final sizeMatch =
        RegExp(r'Size\(([^,]+),\s*([^)]+)\)').firstMatch(cleanValue);
    if (sizeMatch != null) {
      final width = double.tryParse(sizeMatch.group(1)!);
      final height = double.tryParse(sizeMatch.group(2)!);
      if (width != null && height != null) {
        return {'width': width, 'height': height, '_type': 'Size'};
      }
    }

    // Try to parse Offset
    final offsetMatch =
        RegExp(r'Offset\(([^,]+),\s*([^)]+)\)').firstMatch(cleanValue);
    if (offsetMatch != null) {
      final dx = double.tryParse(offsetMatch.group(1)!);
      final dy = double.tryParse(offsetMatch.group(2)!);
      if (dx != null && dy != null) {
        return {'dx': dx, 'dy': dy, '_type': 'Offset'};
      }
    }

    // Try to parse EdgeInsets
    final edgeInsetsMatch =
        RegExp(r'EdgeInsets\(([^,]+),\s*([^,]+),\s*([^,]+),\s*([^)]+)\)')
            .firstMatch(cleanValue);
    if (edgeInsetsMatch != null) {
      final left = double.tryParse(edgeInsetsMatch.group(1)!);
      final top = double.tryParse(edgeInsetsMatch.group(2)!);
      final right = double.tryParse(edgeInsetsMatch.group(3)!);
      final bottom = double.tryParse(edgeInsetsMatch.group(4)!);
      if (left != null && top != null && right != null && bottom != null) {
        return {
          'left': left,
          'top': top,
          'right': right,
          'bottom': bottom,
          '_type': 'EdgeInsets',
        };
      }
    }

    // Return as string if no parsing matched
    return cleanValue;
  }

  static Map<String, dynamic> _getTypeSpecificData(RenderObject renderObject) {
    final data = <String, dynamic>{};

    if (renderObject is RenderBox) {
      data['renderBoxData'] = {
        'hasSize': renderObject.hasSize,
        if (renderObject.hasSize) ...{
          'size': {
            'width': renderObject.size.width,
            'height': renderObject.size.height,
          },
          'constraints': renderObject.constraints.toString(),
        },
        if (renderObject.attached && renderObject.hasSize) ...{
          'globalPosition': _safeGetGlobalPosition(renderObject),
        },
        'semanticBounds': renderObject.semanticBounds.toString(),
      };
    }

    if (renderObject is RenderDecoratedBox) {
      data['decoratedBoxData'] = _getDecoratedBoxData(renderObject);
    }

    if (renderObject is RenderParagraph) {
      data['paragraphData'] = _getParagraphData(renderObject);
    }

    if (renderObject is RenderImage) {
      data['imageData'] = _getImageData(renderObject);
    }

    if (renderObject is RenderFlex) {
      data['flexData'] = {
        'direction': renderObject.direction.toString(),
        'mainAxisAlignment': renderObject.mainAxisAlignment.toString(),
        'crossAxisAlignment': renderObject.crossAxisAlignment.toString(),
        'mainAxisSize': renderObject.mainAxisSize.toString(),
        'textDirection': renderObject.textDirection?.toString(),
        'verticalDirection': renderObject.verticalDirection.toString(),
      };
    }

    if (renderObject is RenderPadding) {
      data['paddingData'] = {
        'padding': renderObject.padding.toString(),
        'textDirection': renderObject.textDirection?.toString(),
      };
    }

    if (renderObject is RenderStack) {
      data['stackData'] = _getStackData(renderObject);
    }

    if (renderObject is RenderTransform) {
      data['transformData'] = {
        'transformMatrix':
            'Matrix4', // RenderTransform doesn't expose transform directly
        'alignment': renderObject.alignment?.toString(),
        'textDirection': renderObject.textDirection?.toString(),
        'transformHitTests': renderObject.transformHitTests,
      };
    }

    if (renderObject is RenderOpacity) {
      data['opacityData'] = {
        'opacity': renderObject.opacity,
        'alwaysIncludeSemantics': renderObject.alwaysIncludeSemantics,
      };
    }

    return data;
  }

  static Map<String, double>? _safeGetGlobalPosition(RenderBox renderBox) {
    try {
      final position = renderBox.localToGlobal(Offset.zero);
      return {'x': position.dx, 'y': position.dy};
    } catch (e) {
      return null;
    }
  }

  static Map<String, dynamic> _getDecoratedBoxData(
    RenderDecoratedBox decoratedBox,
  ) {
    final data = <String, dynamic>{
      'decorationType': decoratedBox.decoration.runtimeType.toString(),
      'position': decoratedBox.position.toString(),
    };

    final decoration = decoratedBox.decoration;
    if (decoration is BoxDecoration) {
      final boxDecorationData = <String, dynamic>{};

      if (decoration.color != null) {
        boxDecorationData['color'] = decoration.color.toString();
      }

      if (decoration.border != null) {
        boxDecorationData['border'] = decoration.border.toString();
      }

      if (decoration.borderRadius != null) {
        boxDecorationData['borderRadius'] = decoration.borderRadius.toString();
      }

      if (decoration.boxShadow != null && decoration.boxShadow!.isNotEmpty) {
        boxDecorationData['boxShadow'] = {
          'count': decoration.boxShadow!.length,
          'shadows':
              decoration.boxShadow!.map((shadow) => shadow.toString()).toList(),
        };
      }

      if (decoration.gradient != null) {
        boxDecorationData['gradient'] = {
          'type': decoration.gradient.runtimeType.toString(),
        };
      }

      if (decoration.image != null) {
        boxDecorationData['backgroundImage'] = {
          'type': decoration.image!.image.runtimeType.toString(),
        };
      }

      boxDecorationData['shape'] = decoration.shape.toString();
      data['boxDecoration'] = boxDecorationData;
    }

    return data;
  }

  static Map<String, dynamic> _getParagraphData(RenderParagraph paragraph) {
    final data = <String, dynamic>{};

    try {
      final text = paragraph.text;
      data['text'] = text.toPlainText();

      if (text.style != null) {
        final style = text.style!;
        final styleData = <String, dynamic>{};

        if (style.fontSize != null) styleData['fontSize'] = style.fontSize;
        if (style.color != null) styleData['color'] = style.color.toString();
        if (style.fontFamily != null) {
          styleData['fontFamily'] = style.fontFamily;
        }
        if (style.fontWeight != null) {
          styleData['fontWeight'] = style.fontWeight.toString();
        }

        data['textStyle'] = styleData;
      }

      data['textAlign'] = paragraph.textAlign.toString();
      data['textDirection'] = paragraph.textDirection.toString();
      data['maxLines'] = paragraph.maxLines;
      data['overflow'] = paragraph.overflow.toString();
    } catch (e) {
      data['text'] = '<unable to access>';
      data['error'] = e.toString();
    }

    return data;
  }

  static Map<String, dynamic> _getImageData(RenderImage image) {
    final data = <String, dynamic>{};

    if (image.image != null) {
      data['imageType'] = image.image.runtimeType.toString();
    }

    data['fit'] = image.fit?.toString();
    data['alignment'] = image.alignment.toString();
    data['repeat'] = image.repeat.toString();

    if (image.color != null) {
      data['color'] = image.color.toString();
    }

    if (image.colorBlendMode != null) {
      data['colorBlendMode'] = image.colorBlendMode.toString();
    }

    return data;
  }

  static Map<String, dynamic> _getStackData(RenderStack stack) {
    final data = <String, dynamic>{
      'alignment': stack.alignment.toString(),
      'textDirection': stack.textDirection?.toString(),
      'fit': stack.fit.toString(),
      'clipBehavior': stack.clipBehavior.toString(),
    };

    // Analyze positioned children
    var positionedCount = 0;
    final positionedChildren = <Map<String, dynamic>>[];

    stack.visitChildren((child) {
      if (child.parentData is StackParentData) {
        final parentData = child.parentData! as StackParentData;
        if (parentData.isPositioned) {
          positionedCount++;
          final positionData = <String, dynamic>{
            'isPositioned': true,
          };

          if (parentData.left != null) positionData['left'] = parentData.left;
          if (parentData.top != null) positionData['top'] = parentData.top;
          if (parentData.right != null) {
            positionData['right'] = parentData.right;
          }
          if (parentData.bottom != null) {
            positionData['bottom'] = parentData.bottom;
          }
          if (parentData.width != null) {
            positionData['width'] = parentData.width;
          }
          if (parentData.height != null) {
            positionData['height'] = parentData.height;
          }

          positionedChildren.add(positionData);
        }
      }
    });

    data['positionedChildrenCount'] = positionedCount;
    if (positionedChildren.isNotEmpty) {
      data['positionedChildren'] = positionedChildren;
    }

    return data;
  }

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
  Map<String, dynamic> toNestedDiagnosticsMap({int maxDepth = 1000}) =>
      DiagnosticsRecreator.getNestedDiagnosticsMap(
        targetRenderBox,
        maxDepth: maxDepth,
      );

  Map<String, dynamic> getStructuredDiagnostics() =>
      DiagnosticsRecreator.getStructuredDiagnostics(targetRenderBox);

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
