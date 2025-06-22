import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';
import 'package:ispect/src/features/ispect/presentation/widgets/share_log_bottom_sheet.dart';
import 'package:ispect/src/features/json_viewer/widgets/explorer.dart';
import 'package:ispect/src/features/json_viewer/widgets/controller/store.dart';
import 'package:ispect/src/features/json_viewer/theme.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class JsonScreen extends StatefulWidget {
  const JsonScreen({
    required this.data,
    this.truncatedData,
    this.onClose,
    super.key,
  });
  final Map<String, dynamic> data;
  final Map<String, dynamic>? truncatedData;
  final VoidCallback? onClose;

  void push(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => this,
        settings: const RouteSettings(name: 'ISpect Log Screen'),
      ),
    );
  }

  @override
  State<JsonScreen> createState() => _JsonScreenState();
}

class _JsonScreenState extends State<JsonScreen> {
  final _store = JsonExplorerStore();
  final _searchController = TextEditingController();
  final _itemScrollController = ItemScrollController();

  late JsonExplorerTheme _jsonTheme;

  // Debounce timer for search
  Timer? _searchDebounceTimer;

  @override
  void initState() {
    super.initState();

    _store.buildNodes(widget.data);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _jsonTheme = JsonExplorerTheme(
      propertyKeyTextStyle: TextStyle(
        color: context.ispectTheme.colorScheme.primary,
        fontWeight: FontWeight.bold,
      ),
      rootKeyTextStyle: TextStyle(
        color: context.ispectTheme.colorScheme.primary,
        fontWeight: FontWeight.bold,
      ),
      valueSearchHighlightTextStyle: const TextStyle(
        color: Colors.black87,
        backgroundColor: Color.fromARGB(228, 255, 235, 59),
      ),
      focusedValueSearchHighlightTextStyle: const TextStyle(
        color: Colors.black,
        backgroundColor: Colors.yellow,
        fontWeight: FontWeight.bold,
      ),
      keySearchHighlightTextStyle: const TextStyle(
        color: Colors.black87,
        backgroundColor: Color.fromARGB(228, 255, 235, 59),
      ),
      focusedKeySearchHighlightTextStyle: const TextStyle(
        color: Colors.black,
        backgroundColor: Colors.yellow,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounceTimer?.cancel();
    _store.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        _store
          ..search(value)
          ..expandSearchResults();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final iSpect = ISpect.read(context);
    return ChangeNotifierProvider.value(
      value: _store,
      child: Scaffold(
        backgroundColor: iSpect.theme.backgroundColor(context),
        appBar: AppBar(
          scrolledUnderElevation: 0,
          backgroundColor: iSpect.theme.backgroundColor(context),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: widget.onClose ?? () => Navigator.of(context).pop(),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.unfold_more_rounded),
                    onPressed: _store.expandAll,
                  ),
                  IconButton(
                    icon: const Icon(Icons.unfold_less_rounded),
                    onPressed: _store.collapseAll,
                  ),
                  IconButton(
                    icon: const Icon(Icons.share_rounded),
                    onPressed: () async {
                      await ISpectShareLogBottomSheet(
                        data: widget.data,
                        truncatedData: widget.truncatedData ?? widget.data,
                      ).show(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            const Gap(12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: SearchBar(
                      constraints: const BoxConstraints(minHeight: 45),
                      shape: const WidgetStatePropertyAll(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                      ),
                      leading: const Icon(Icons.search),
                      onChanged: _onSearchChanged,
                      hintText: context.ispectL10n.search,
                      controller: _searchController,
                      elevation: WidgetStateProperty.all(0),
                    ),
                  ),
                  const Gap(8),
                  Selector<JsonExplorerStore, ({int count, int focusedIndex})>(
                    selector: (_, store) => (
                      count: store.searchResults.length,
                      focusedIndex: store.focusedSearchResultIndex,
                    ),
                    builder: (context, searchData, child) {
                      if (searchData.count == 0) {
                        return const SizedBox.shrink();
                      }
                      return _SearchNavigationPanel(
                        store: _store,
                        scrollToSearchMatch: _scrollToSearchMatch,
                        searchFocusText:
                            '${searchData.focusedIndex + 1} of ${searchData.count}',
                      );
                    },
                  ),
                ],
              ),
            ),
            const Gap(12),
            Expanded(
              child: Consumer<JsonExplorerStore>(
                builder: (context, model, child) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: JsonExplorer(
                    nodes: model.displayNodes,
                    itemScrollController: _itemScrollController,
                    theme: _jsonTheme,
                  ),
                ),
              ),
            ),
            const Gap(32),
          ],
        ),
      ),
    );
  }

  Future<void> _scrollToSearchMatch(JsonExplorerStore store) async {
    final searchResult = store.focusedSearchResult;
    if (!mounted) return;

    // Expand the node and all its parents to ensure it's visible
    // We want to handle the nodes in a single batch operation
    _store.expandParentNodes(searchResult.node);

    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    final displayNodes = _store.displayNodes;

    // First check if the exact node is visible
    final nodeIndex = displayNodes.indexOf(searchResult.node);
    if (nodeIndex != -1) {
      await _scrollToIndex(nodeIndex);
      return;
    }

    // Find the closest parent that's visible
    var currentNode = searchResult.node.parent;
    while (currentNode != null) {
      final parentIndex = displayNodes.indexOf(currentNode);
      if (parentIndex != -1) {
        await _scrollToIndex(parentIndex);
        return;
      }
      currentNode = currentNode.parent;
    }

    // Last resort: scroll to first item if available
    if (displayNodes.isNotEmpty) {
      await _scrollToIndex(0);
    }
  }

  Future<void> _scrollToIndex(int index) => _itemScrollController.scrollTo(
        index: index,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
}

class _SearchNavigationPanel extends StatelessWidget {
  const _SearchNavigationPanel({
    required this.store,
    required this.scrollToSearchMatch,
    required this.searchFocusText,
  });

  final JsonExplorerStore store;
  final Future<void> Function(JsonExplorerStore) scrollToSearchMatch;
  final String searchFocusText;

  void _onPreviousPressed() {
    store.focusPreviousSearchResult();
    scrollToSearchMatch(store);
  }

  void _onNextPressed() {
    store.focusNextSearchResult();
    scrollToSearchMatch(store);
  }

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            searchFocusText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w200,
              color: Colors.grey,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _onPreviousPressed,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minHeight: 36,
                  minWidth: 36,
                ),
                icon: const Icon(Icons.arrow_drop_up_rounded),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: _onNextPressed,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minHeight: 36,
                  minWidth: 36,
                ),
                icon: const Icon(Icons.arrow_drop_down_rounded),
              ),
            ],
          ),
        ],
      );
}
