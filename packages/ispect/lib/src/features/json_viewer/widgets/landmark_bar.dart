import 'package:flutter/material.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';
import 'package:ispect/src/core/res/constants/ispect_constants.dart';
import 'package:ispect/src/features/json_viewer/models/json_outline.dart';
import 'package:ispect/src/features/json_viewer/models/node_view_model.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/log_card/network_transaction_badges.dart';

class JsonLandmarkBar extends StatelessWidget {
  const JsonLandmarkBar({
    required this.landmarks,
    required this.active,
    required this.activeColor,
    required this.onSelected,
    super.key,
  });

  final List<ResolvedJsonLandmark> landmarks;
  final JsonLandmark? active;
  final Color activeColor;
  final ValueChanged<NodeViewModelState> onSelected;

  @override
  Widget build(BuildContext context) {
    final restColor = context.appTheme.colorScheme.onSurface.withValues(
      alpha: 0.8,
    );
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            for (final (index, (:landmark, :node)) in landmarks.indexed) ...[
              if (index > 0) const Gap(ISpectConstants.standardGap),
              DetailChip(
                key: ValueKey('json-landmark-${landmark.id}'),
                label: landmark.showsCount
                    ? '${landmark.label(context)} (${node.children.length})'
                    : landmark.label(context),
                icon: landmark.icon,
                color: identical(landmark, active) ? activeColor : restColor,
                onTap: () => onSelected(node),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
