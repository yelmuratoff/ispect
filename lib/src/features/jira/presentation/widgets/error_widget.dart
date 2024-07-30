import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class JiraErrorWidget extends StatelessWidget {
  const JiraErrorWidget({required this.error, required this.stackTrace, super.key});
  final Object error;
  final StackTrace stackTrace;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $error'),
            const Gap(8),
            Text('Stack trace: $stackTrace'),
          ],
        ),
      );
}
