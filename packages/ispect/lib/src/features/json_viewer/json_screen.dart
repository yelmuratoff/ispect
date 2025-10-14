import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';
import 'package:ispect/src/features/ispect/presentation/widgets/share_log_bottom_sheet.dart';
import 'package:ispect/src/features/json_viewer/theme.dart';
import 'package:ispect/src/features/json_viewer/widgets/controller/store.dart';
import 'package:ispect/src/features/json_viewer/widgets/explorer.dart';
import 'package:ispect/src/features/json_viewer/widgets/store_selector.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

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

  final _scrollController = ScrollController();
  final _listController = ListController();

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

    _jsonTheme = JsonExplorerTheme.defaultThemeByContext(context);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _searchDebounceTimer?.cancel();
    _listController.dispose();
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
    return Scaffold(
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
                if (context.iSpect.options.onShare != null)
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
                JsonStoreSelector<({int count, int focusedIndex})>(
                  store: _store,
                  selector: (store) => (
                    count: store.searchResults.length,
                    focusedIndex: store.focusedSearchResultIndex,
                  ),
                  builder: (context, searchData) {
                    final count = searchData.count;
                    final focusedIndex = searchData.focusedIndex;
                    if (count == 0) {
                      return const SizedBox.shrink();
                    }
                    return _SearchNavigationPanel(
                      store: _store,
                      scrollToSearchMatch: _scrollToSearchMatch,
                      searchFocusText: '${focusedIndex + 1} of $count',
                    );
                  },
                ),
              ],
            ),
          ),
          const Gap(12),
          Expanded(
            child: AnimatedBuilder(
              animation: _store,
              builder: (context, _) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: JsonExplorer(
                  store: _store,
                  nodes: _store.displayNodes,
                  listController: _listController,
                  scrollController: _scrollController,
                  theme: _jsonTheme,
                ),
              ),
            ),
          ),
          const Gap(32),
        ],
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

  Future<void> _scrollToIndex(int index) async {
    _listController.animateToItem(
      index: index,
      duration: (estimatedDistance) => const Duration(milliseconds: 250),
      curve: (estimatedDistance) => Curves.easeOutCubic,
      scrollController: _scrollController,
      alignment: 0.5,
    );
  }
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
            spacing: 12,
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
