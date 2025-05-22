import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/utils/copy_clipboard.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';
import 'package:ispect/src/features/json_viewer/explorer.dart';
import 'package:ispect/src/features/json_viewer/store.dart';
import 'package:ispect/src/features/json_viewer/theme.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class LogScreen extends StatefulWidget {
  const LogScreen({required this.data, super.key});
  final ISpectifyData data;

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  late final ISpectifyData _data;
  final JsonExplorerStore _store = JsonExplorerStore();
  final TextEditingController _searchController = TextEditingController();
  final ItemScrollController _itemScrollController = ItemScrollController();

  late final JsonExplorerTheme _jsonTheme;
  late final String _screenTitle;

  // Debounce timer for search
  Timer? _searchDebounceTimer;

  @override
  void initState() {
    super.initState();
    _data = widget.data;
    _store.buildNodes(_data.toJson());
    _screenTitle = _title(_data.key ?? '');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Cache theme computation since it involves context lookups
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
          backgroundColor: iSpect.theme.backgroundColor(context),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(_screenTitle),
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
                    icon: const Icon(Icons.copy_rounded),
                    onPressed: () {
                      copyClipboard(
                        context,
                        value: _data.toJson(truncated: true).toString(),
                      );
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
                  const SizedBox(width: 8),
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
                builder: (context, model, child) => JsonExplorer(
                  nodes: model.displayNodes,
                  itemScrollController: _itemScrollController,
                  theme: _jsonTheme,
                ),
              ),
            ),
            const Gap(32),
          ],
        ),
      ),
    );
  }

  String _title(String key) => switch (key) {
        'http-request' => 'HTTP Request',
        'http-response' => 'HTTP Response',
        'http-error' => 'HTTP Error',
        _ => 'Detailed log: $key',
      };

  Future<void> _scrollToSearchMatch(JsonExplorerStore store) async {
    final searchResult = store.focusedSearchResult;
    final parent = searchResult.node.parent;

    if (parent != null) {
      _store.expandParentNodes(searchResult.node);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;

      final parentIndex = _store.displayNodes.indexOf(parent);
      if (parentIndex != -1) {
        await _itemScrollController.scrollTo(
          index: parentIndex,
          duration: const Duration(milliseconds: 300),
        );
      }
    } else {
      final nodeIndex = _store.displayNodes.indexOf(searchResult.node);
      if (nodeIndex != -1) {
        await _itemScrollController.scrollTo(
          index: nodeIndex,
          duration: const Duration(milliseconds: 300),
        );
      }
    }
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
          Text(searchFocusText),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _onPreviousPressed,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.arrow_drop_up_rounded),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _onNextPressed,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.arrow_drop_down_rounded),
              ),
            ],
          ),
        ],
      );
}
