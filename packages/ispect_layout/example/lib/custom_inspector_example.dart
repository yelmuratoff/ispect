import 'package:flutter/material.dart';
import 'package:ispect_layout/ispect_layout.dart';
import 'package:draggable_panel/draggable_panel.dart';

void main() {
  runApp(const CustomInspectorExample());
}

class CustomInspectorExample extends StatelessWidget {
  const CustomInspectorExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, child) {
        return Inspector(
          child: child!,
          panelBuilder: (context, controller, child) {
            return ListenableBuilder(
              listenable: controller.modeNotifier,
              child: child,
              builder: (context, child) => DraggableActionPanel(
                actions: [
                  PanelAction(
                    icon: Icons.format_shapes,
                    badge:
                        controller.modeNotifier.value == InspectorMode.inspector
                        ? const PanelBadge.dot()
                        : null,
                    onPressed: () {
                      controller.setMode(
                        controller.modeNotifier.value == InspectorMode.inspector
                            ? InspectorMode.none
                            : InspectorMode.inspector,
                      );
                    },
                  ),
                  PanelAction(
                    icon: Icons.colorize,
                    badge:
                        controller.modeNotifier.value ==
                            InspectorMode.colorPicker
                        ? const PanelBadge.dot()
                        : null,
                    onPressed: () {
                      controller.setMode(
                        controller.modeNotifier.value ==
                                InspectorMode.colorPicker
                            ? InspectorMode.none
                            : InspectorMode.colorPicker,
                        context: context,
                      );
                    },
                  ),
                  PanelAction(
                    icon: Icons.zoom_in,
                    badge: controller.modeNotifier.value == InspectorMode.zoom
                        ? const PanelBadge.dot()
                        : null,
                    onPressed: () {
                      controller.setMode(
                        controller.modeNotifier.value == InspectorMode.zoom
                            ? InspectorMode.none
                            : InspectorMode.zoom,
                      );
                    },
                  ),
                ],
                child: child,
              ),
            );
          },
        );
      },
      home: Scaffold(
        appBar: AppBar(title: const Text('Custom Inspector Example')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                color: Colors.red,
                child: const Center(child: Text('Red Box')),
              ),
              const SizedBox(height: 20),
              Container(
                width: 100,
                height: 100,
                color: Colors.blue,
                child: const Center(child: Text('Blue Box')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
