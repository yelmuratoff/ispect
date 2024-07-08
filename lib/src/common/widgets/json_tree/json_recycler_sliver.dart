import 'package:flutter/material.dart';
import 'package:ispect/src/common/controllers/json_recycler_controller.dart';
import 'package:ispect/src/common/widgets/json_tree/widgets/base/base_recycler_page_state.dart';
import 'package:ispect/src/common/widgets/json_tree/widgets/item_recycler_widget.dart';

class JsonRecyclerSliver extends StatefulWidget {
  const JsonRecyclerSliver({
    required this.jsonController,
    required this.json,
    super.key,
    this.rootExpanded = false,
  });

  final JsonRecyclerController jsonController;
  final dynamic json;
  final bool rootExpanded;

  @override
  State<JsonRecyclerSliver> createState() => _JsonRecyclerSliverState();
}

class _JsonRecyclerSliverState
    extends BaseRecyclerPageState<JsonRecyclerSliver> {
  @override
  late dynamic json = widget.json;

  @override
  late JsonRecyclerController jsonController = widget.jsonController;

  @override
  bool get rootExpanded => widget.rootExpanded;

  @override
  Widget bodyWidget(BuildContext context) => SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, index) {
            final indexWithShift = jsonList[index].shiftIndex;
            final jsonElement = jsonList[indexWithShift];
            return ItemRecyclerWidget(
              jsonList: widget.json,
              jsonController: widget.jsonController,
              jsonElement: jsonElement,
              callback: () => rememberIndexOfParent(
                indexWithShift,
                index,
              ),
            );
          },
          childCount: jsonListLength,
        ),
      );
}
