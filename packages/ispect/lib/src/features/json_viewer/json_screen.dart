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
  final _hasSearchText = ValueNotifier(false);

  final _scrollController = ScrollController();
  final _listController = ListController();

  late JsonExplorerTheme _jsonTheme;

  Timer? _searchDebounceTimer;

  @override
  void initState() {
    super.initState();
    _store.buildNodes(widget.data);
  }

  @override
  void didUpdateWidget(covariant JsonScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.data, widget.data)) {
      _store.buildNodes(widget.data);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _jsonTheme = JsonExplorerTheme.defaultThemeByContext(context);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _hasSearchText.dispose();
    _scrollController.dispose();
    _searchDebounceTimer?.cancel();
    _listController.dispose();
    _store.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _hasSearchText.value = value.isNotEmpty;
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted && _store.mounted) {
        _store.search(value);
      }
    });
  }

  void _onSearchClear() {
    _searchController.clear();
    _hasSearchText.value = false;
    _store.search('');
  }

  @override
  Widget build(BuildContext context) {
    final iSpect = ISpect.read(context);
    final bgColor = iSpect.theme.background?.resolve(context);
    final logKey = widget.data['key'] as String?;
    final logColor = iSpect.theme.getTypeColor(context, key: logKey);
    final logIcon = iSpect.theme.getTypeIcon(context, key: logKey);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        backgroundColor: bgColor ?? context.appTheme.scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: widget.onClose ?? () => Navigator.of(context).pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (logColor != null)
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: logColor.withValues(alpha: 0.12),
                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                ),
                child: Icon(logIcon, size: 16, color: logColor),
              ),
            const Gap(10),
            Text(
              logKey ?? 'JSON Viewer',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: logColor,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.unfold_more_rounded, size: 22),
            tooltip: context.ispectL10n.expandLogs,
            onPressed: _store.expandAll,
          ),
          IconButton(
            icon: const Icon(Icons.unfold_less_rounded, size: 22),
            tooltip: context.ispectL10n.collapseLogs,
            onPressed: _store.collapseAll,
          ),
          if (context.iSpect.options.onShare != null)
            IconButton(
              icon: const Icon(Icons.share_rounded, size: 22),
              tooltip: context.ispectL10n.shareLogsFile,
              onPressed: () async {
                await ISpectShareLogBottomSheet(
                  data: widget.data,
                  truncatedData: widget.truncatedData ?? widget.data,
                ).show(context);
              },
            ),
          const Gap(4),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: ValueListenableBuilder(
              valueListenable: _hasSearchText,
              builder: (context, hasText, _) => Row(
                children: [
                  Expanded(
                    child: SearchBar(
                      controller: _searchController,
                      constraints: const BoxConstraints(minHeight: 42),
                      backgroundColor: WidgetStatePropertyAll(
                        context.ispectTheme.card?.resolve(context),
                      ),
                      shape: const WidgetStatePropertyAll(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                      ),
                      leading: Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: context.appTheme.colorScheme.onSurface
                              .withValues(alpha: 0.5),
                        ),
                      ),
                      trailing: [
                        if (hasText)
                          IconButton(
                            iconSize: 18,
                            constraints: const BoxConstraints.tightFor(
                              width: 28,
                              height: 28,
                            ),
                            padding: EdgeInsets.zero,
                            onPressed: _onSearchClear,
                            icon: Icon(
                              Icons.close_rounded,
                              color: context.appTheme.colorScheme.onSurface
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                      ],
                      hintText: context.ispectL10n.search,
                      onChanged: _onSearchChanged,
                      elevation: const WidgetStatePropertyAll(0),
                    ),
                  ),
                  JsonStoreSelector<
                      ({
                        int count,
                        int focusedIndex,
                        bool hasSearchTerm,
                        bool isSearching,
                      })>(
                    store: _store,
                    selector: (s) => (
                      count: s.searchResults.length,
                      focusedIndex: s.focusedSearchResultIndex,
                      hasSearchTerm: s.searchTerm.isNotEmpty,
                      isSearching: s.isSearching,
                    ),
                    builder: (context, searchData) {
                      if (!searchData.hasSearchTerm) {
                        return const SizedBox.shrink();
                      }
                      if (searchData.isSearching) {
                        return const _SearchLoadingIndicator();
                      }
                      final count = searchData.count;
                      final focusedIndex = searchData.focusedIndex;
                      return switch (count) {
                        0 => _NoResultsLabel(),
                        _ => _SearchNavigation(
                            store: _store,
                            scrollToSearchMatch: _scrollToSearchMatch,
                            focusedIndex: focusedIndex + 1,
                            totalCount: count,
                          ),
                      };
                    },
                  ),
                ],
              ),
            ),
          ),
          // JSON viewer
          Expanded(
            child: AnimatedBuilder(
              animation: _store,
              builder: (context, _) => Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 8, 8),
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
        ],
      ),
    );
  }

  Future<void> _scrollToSearchMatch(JsonExplorerStore store) async {
    final searchResult = store.focusedSearchResult;
    if (searchResult == null || !mounted) return;

    _store.expandParentNodes(searchResult.node);

    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    final displayNodes = _store.displayNodes;

    final nodeIndex = displayNodes.indexOf(searchResult.node);
    switch (nodeIndex) {
      case -1:
        break;
      default:
        _scrollToIndex(nodeIndex);
        return;
    }

    for (var currentNode = searchResult.node.parent;
        currentNode != null;
        currentNode = currentNode.parent) {
      final parentIndex = displayNodes.indexOf(currentNode);
      switch (parentIndex) {
        case -1:
          break;
        default:
          _scrollToIndex(parentIndex);
          return;
      }
    }

    switch (displayNodes.isEmpty) {
      case false:
        _scrollToIndex(0);
      case true:
        break;
    }
  }

  void _scrollToIndex(int index) {
    _listController.animateToItem(
      index: index,
      duration: (estimatedDistance) => const Duration(milliseconds: 250),
      curve: (estimatedDistance) => Curves.easeOutCubic,
      scrollController: _scrollController,
      alignment: 0.5,
    );
  }
}

/// Inline search navigation: [▲] 1/5 [▼]
class _SearchNavigation extends StatelessWidget {
  const _SearchNavigation({
    required this.store,
    required this.scrollToSearchMatch,
    required this.focusedIndex,
    required this.totalCount,
  });

  final JsonExplorerStore store;
  final Future<void> Function(JsonExplorerStore) scrollToSearchMatch;
  final int focusedIndex;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final mutedColor =
        context.appTheme.colorScheme.onSurface.withValues(alpha: 0.5);

    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _NavButton(
            icon: Icons.keyboard_arrow_up_rounded,
            onPressed: () {
              store.focusPreviousSearchResult(loop: true);
              unawaited(
                scrollToSearchMatch(store).catchError((Object error) {
                  assert(() {
                    debugPrint('scrollToSearchMatch failed: $error');
                    return true;
                  }());
                }),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              '$focusedIndex/$totalCount',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: mutedColor,
              ),
            ),
          ),
          _NavButton(
            icon: Icons.keyboard_arrow_down_rounded,
            onPressed: () {
              store.focusNextSearchResult(loop: true);
              unawaited(
                scrollToSearchMatch(store).catchError((Object error) {
                  assert(() {
                    debugPrint('scrollToSearchMatch failed: $error');
                    return true;
                  }());
                }),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SearchLoadingIndicator extends StatelessWidget {
  const _SearchLoadingIndicator();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 12),
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color:
                context.appTheme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
      );
}

class _NoResultsLabel extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Text(
          '0/0',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: context.appTheme.colorScheme.error.withValues(alpha: 0.7),
          ),
        ),
      );
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 28,
        height: 28,
        child: IconButton(
          icon: Icon(icon, size: 20),
          onPressed: onPressed,
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          color: context.appTheme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      );
}
