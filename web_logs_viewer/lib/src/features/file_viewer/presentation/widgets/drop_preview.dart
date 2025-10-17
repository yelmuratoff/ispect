import 'package:flutter/material.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

import 'drop_item_info.dart';

class DropPreview extends StatelessWidget {
  const DropPreview({super.key, required this.items});

  final List<DropItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        color: Colors.black.withValues(alpha: 0.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(50),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: ListView(
                shrinkWrap: true,
                children: items
                    .map<Widget>((e) => DropItemInfo(dropItem: e))
                    .toList(growable: false),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
