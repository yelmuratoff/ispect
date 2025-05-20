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
  final _store = JsonExplorerStore();
  final _searchController = TextEditingController();
  final _itemScrollController = ItemScrollController();

  @override
  void initState() {
    super.initState();
    _data = widget.data;
    _store.buildNodes(
      _data.toJson(),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _searchController.dispose();
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
          title: Text(_title(_data.key ?? '')),
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
        body: Consumer<JsonExplorerStore>(
          builder: (context, model, child) => Column(
            children: [
              //
              // <--- Search bar --->
              //
              const Gap(12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: SearchBar(
                        constraints: const BoxConstraints(
                          minHeight: 45,
                        ),
                        shape: const WidgetStatePropertyAll(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(12),
                            ),
                          ),
                        ),
                        leading: const Icon(Icons.search),
                        onChanged: (value) {
                          model
                            ..search(value)
                            ..expandSearchResults();
                        },
                        hintText: context.ispectL10n.search,
                        controller: _searchController,
                        elevation: WidgetStateProperty.all(0),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (model.searchResults.isNotEmpty)
                      Text(
                        _searchFocusText(),
                      ),
                    if (model.searchResults.isNotEmpty)
                      IconButton(
                        onPressed: () {
                          model.focusPreviousSearchResult();
                          _scrollToSearchMatch(
                            model,
                          );
                        },
                        icon: const Icon(Icons.arrow_drop_up),
                      ),
                    if (model.searchResults.isNotEmpty)
                      IconButton(
                        onPressed: () {
                          model.focusNextSearchResult();
                          _scrollToSearchMatch(
                            model,
                          );
                        },
                        icon: const Icon(Icons.arrow_drop_down),
                      ),
                  ],
                ),
              ),
              const Gap(12),
              //
              // <--- Json Tree --->
              //
              Expanded(
                child: JsonExplorer(
                  nodes: model.displayNodes,
                  itemScrollController: _itemScrollController,
                  theme: JsonExplorerTheme(
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
                  ),
                ),
              ),
              const Gap(32),
            ],
          ),
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

  String _searchFocusText() =>
      '${_store.focusedSearchResultIndex + 1} of ${_store.searchResults.length}';

  Future<void> _scrollToSearchMatch(JsonExplorerStore store) async {
    final index = store.focusedSearchResultIndex;
    final parent = store.focusedSearchResult.node.parent;
    final parentIndex = _store.displayNodes.indexOf(parent);

    if (parent != null) {
      _store.expandParentNodes(
        store.focusedSearchResult.node,
      );

      await Future<void>.delayed(
        const Duration(milliseconds: 100),
      );

      if (parentIndex != -1) {
        await _itemScrollController.scrollTo(
          index: parentIndex,
          duration: const Duration(milliseconds: 300),
        );
      }
    } else if (index != -1) {
      await _itemScrollController.scrollTo(
        index: index,
        duration: const Duration(milliseconds: 300),
      );
    }
  }
}
