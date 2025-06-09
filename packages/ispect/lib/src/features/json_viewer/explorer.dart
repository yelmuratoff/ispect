import 'package:flutter/material.dart';
import 'package:ispect/src/features/json_viewer/json_attribute.dart';
import 'package:ispect/src/features/json_viewer/store.dart';
import 'package:ispect/src/features/json_viewer/theme.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

/// Signature for a function that creates a widget based on a
/// `NodeViewModelState` state.
typedef NodeBuilder = Widget Function(
  BuildContext context,
  NodeViewModelState node,
);

/// Signature for a function that takes a generic value and converts it to a
/// string.
typedef Formatter = String Function(Object? value);

/// Signature for a function that takes a generic value and the current theme
/// property value style and returns a `StyleBuilder` that allows the style
/// and interaction to be changed dynamically.
///
/// See also:
/// * `PropertyStyle`
typedef StyleBuilder = PropertyOverrides Function(
  Object? value,
  TextStyle style,
);

/// Holds information about a property value style and interaction.
class PropertyOverrides {
  const PropertyOverrides({required this.style, this.onTap});
  final TextStyle style;
  final VoidCallback? onTap;
}

/// A widget to display a list of Json nodes.
///
/// The `JsonExplorerStore` handles the state of the data structure, so a
/// `JsonExplorerStore` must be available through a [Provider] for this widget
/// to fully function, without it, expand and collapse will not work properly.
///
/// {@tool snippet}
/// ```dart
/// JsonExplorerStore store;
/// // ...
/// ChangeNotifierProvider.value(
///   value: store,
///   child:
/// // ...
/// ```
/// {@end-tool}
///
/// And then a `JsonExplorer` can be built using the store data structure:
/// {@tool snippet}
/// ```dart
/// Widget build(BuildContext context) {
///   return Scaffold(
///     appBar: AppBar(
///       title: Text(widget.title),
///     ),
///     body: SafeArea(
///       minimum: const EdgeInsets.all(16),
///       child: ChangeNotifierProvider.value(
///         value: store,
///         child: Consumer<JsonExplorerStore>(
///           builder: (context, state, child) => JsonExplorer(
///             nodes: state.displayNodes,
///           ),
///         ),
///       ),
///     ),
///   );
/// }
/// ```
/// {@end-tool}
class JsonExplorer extends StatelessWidget {
  const JsonExplorer({
    required this.nodes,
    super.key,
    this.itemScrollController,
    this.itemPositionsListener,
    this.rootInformationBuilder,
    this.collapsableToggleBuilder,
    this.trailingBuilder,
    this.rootNameFormatter,
    this.propertyNameFormatter,
    this.valueFormatter,
    this.valueStyleBuilder,
    this.itemSpacing = 4,
    this.physics,
    this.maxRootNodeWidth,
    JsonExplorerTheme? theme,
  }) : theme = theme ?? JsonExplorerTheme.defaultTheme;

  /// Nodes to be displayed.
  ///
  /// See also:
  /// * `JsonExplorerStore`
  final Iterable<NodeViewModelState> nodes;

  /// Use to control the scroll.
  ///
  /// Used to jump or scroll to a particular position.
  final ItemScrollController? itemScrollController;

  /// Use to listen to scroll position changes.
  final ItemPositionsListener? itemPositionsListener;

  /// Theme used to render the widgets.
  ///
  /// If not set, a default theme will be used.
  final JsonExplorerTheme theme;

  /// A builder to add a widget as a suffix for root nodes.
  ///
  /// This can be used to display useful information such as the number of
  /// children nodes, or to indicate if the node is class or an array
  /// for example.
  final NodeBuilder? rootInformationBuilder;

  /// Build the expand/collapse icons in root nodes.
  ///
  /// If this builder is null, a material `Icons.arrow_right` is displayed for
  /// collapsed nodes and `Icons.arrow_drop_down` for expanded nodes.
  final NodeBuilder? collapsableToggleBuilder;

  /// A builder to add a trailing widget in each node.
  ///
  /// This widget is added to the end of the node on top of the content.
  final NodeBuilder? trailingBuilder;

  /// Customizes how class/array names are formatted as string.
  ///
  /// By default the class and array names are displayed as follows: 'name:'
  final Formatter? rootNameFormatter;

  /// Customizes how property names are formatted as string.
  ///
  /// By default the property names are displayed as follows: 'name:'
  final Formatter? propertyNameFormatter;

  /// Customizes how property values are formatted as string.
  ///
  /// By default the value is converted to a string by calling the .toString()
  /// method.
  final Formatter? valueFormatter;

  /// Customizes a property style and interaction based on its value.
  ///
  /// See also:
  /// * `StyleBuilder`
  final StyleBuilder? valueStyleBuilder;

  /// Sets the spacing between each list item.
  final double itemSpacing;

  /// Sets the scroll physics of the list.
  final ScrollPhysics? physics;

  final double? maxRootNodeWidth;

  @override
  Widget build(BuildContext context) => SelectionArea(
        child: ScrollablePositionedList.builder(
          itemCount: nodes.length,
          itemScrollController: itemScrollController,
          itemPositionsListener: itemPositionsListener,
          itemBuilder: (context, index) {
            final node = nodes.elementAt(index);
            return _JsonAttributeItem(
              node: node,
              theme: theme,
              rootInformationBuilder: rootInformationBuilder,
              collapsableToggleBuilder: collapsableToggleBuilder,
              trailingBuilder: trailingBuilder,
              rootNameFormatter: rootNameFormatter,
              propertyNameFormatter: propertyNameFormatter,
              valueFormatter: valueFormatter,
              valueStyleBuilder: valueStyleBuilder,
              itemSpacing: itemSpacing,
              maxRootNodeWidth: maxRootNodeWidth,
            );
          },
          physics: physics,
        ),
      );
}

/// A wrapper widget that caches the JsonAttribute widget inside an AnimatedBuilder
/// This reduces unnecessary rebuilds of the JsonAttribute widget
class _JsonAttributeItem extends StatelessWidget {
  const _JsonAttributeItem({
    required this.node,
    required this.theme,
    this.rootInformationBuilder,
    this.collapsableToggleBuilder,
    this.trailingBuilder,
    this.rootNameFormatter,
    this.propertyNameFormatter,
    this.valueFormatter,
    this.valueStyleBuilder,
    this.itemSpacing = 4,
    this.maxRootNodeWidth,
  });

  final NodeViewModelState node;
  final JsonExplorerTheme theme;
  final NodeBuilder? rootInformationBuilder;
  final NodeBuilder? collapsableToggleBuilder;
  final NodeBuilder? trailingBuilder;
  final Formatter? rootNameFormatter;
  final Formatter? propertyNameFormatter;
  final Formatter? valueFormatter;
  final StyleBuilder? valueStyleBuilder;
  final double itemSpacing;
  final double? maxRootNodeWidth;

  @override
  Widget build(BuildContext context) {
    // Create the JsonAttribute once and reuse it
    final jsonAttr = JsonAttribute(
      node: node,
      rootInformationBuilder: rootInformationBuilder,
      collapsableToggleBuilder: collapsableToggleBuilder,
      trailingBuilder: trailingBuilder,
      rootNameFormatter: rootNameFormatter,
      propertyNameFormatter: propertyNameFormatter,
      valueFormatter: valueFormatter,
      valueStyleBuilder: valueStyleBuilder,
      itemSpacing: itemSpacing,
      theme: theme,
      maxRootNodeWidth: maxRootNodeWidth,
    );

    return AnimatedBuilder(
      animation: node,
      builder: (context, child) => DecoratedBox(
        decoration: BoxDecoration(
          color: node.isHighlighted ? theme.highlightColor : null,
        ),
        child: child,
      ),
      child: jsonAttr,
    );
  }
}
