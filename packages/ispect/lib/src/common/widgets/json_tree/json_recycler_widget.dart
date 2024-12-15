import 'package:flutter/material.dart';
import 'package:ispect/src/common/controllers/json_recycler_controller.dart';
import 'package:ispect/src/common/widgets/json_tree/widgets/base/base_recycler_page_state.dart';
import 'package:ispect/src/common/widgets/json_tree/widgets/item_recycler_widget.dart';

class JsonRecyclerWidget extends StatefulWidget {
  const JsonRecyclerWidget({
    required this.jsonController,
    required this.json,
    super.key,
    this.rootExpanded = false,
    this.useShrinkWrap = false,
  });

  final JsonRecyclerController jsonController;
  final dynamic json;
  final bool rootExpanded;
  final bool useShrinkWrap;

  @override
  State<JsonRecyclerWidget> createState() => _JsonRecyclerWidgetState();
}

class _JsonRecyclerWidgetState
    extends BaseRecyclerPageState<JsonRecyclerWidget> {
  @override
  late dynamic json = widget.json;

  @override
  bool get rootExpanded => widget.rootExpanded;

  @override
  late JsonRecyclerController jsonController = widget.jsonController;

  @override
  Widget bodyWidget(BuildContext context) => ListView.builder(
        itemCount: jsonListLength,
        shrinkWrap: widget.useShrinkWrap,
        physics: widget.useShrinkWrap
            ? const NeverScrollableScrollPhysics()
            : const AlwaysScrollableScrollPhysics(),
        itemBuilder: (_, index) {
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
      );
}
