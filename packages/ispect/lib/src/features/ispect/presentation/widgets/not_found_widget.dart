part of '../screens/ispect_screen.dart';

class _NotFoundWidget extends StatelessWidget {
  const _NotFoundWidget();

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 40,
            color: Colors.white70,
          ),
          const Gap(8),
          Text(
            context.ispectL10n.notFound.capitalize(),
            style: context.ispectTheme.textTheme.bodyLarge,
          ),
        ],
      );
}
