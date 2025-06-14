import 'package:flutter/material.dart';
import 'package:ispect/src/features/inspector/src/widgets/inspector/box_info.dart';

class InspectorDiagnosticScreen extends StatefulWidget {
  const InspectorDiagnosticScreen({required this.info, super.key});

  final BoxInfo info;

  @override
  State<InspectorDiagnosticScreen> createState() =>
      _InspectorDiagnosticScreenState();
}

class _InspectorDiagnosticScreenState extends State<InspectorDiagnosticScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}
