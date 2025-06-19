import 'package:flutter/material.dart';
import 'package:ispect/src/common/observers/route_observer.dart';

class ISpectNavigationFlowScreen extends StatefulWidget {
  const ISpectNavigationFlowScreen({required this.observer, super.key});

  final ISpectNavigatorObserver observer;

  @override
  State<ISpectNavigationFlowScreen> createState() =>
      _ISpectNavigationFlowScreenState();
}

class _ISpectNavigationFlowScreenState
    extends State<ISpectNavigationFlowScreen> {
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Navigation Flow'),
          leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(
              Icons.arrow_back_rounded,
            ),
          ),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount =
                (constraints.maxWidth / 140).floor().clamp(1, 8);
            return GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 40 / 20,
              ),
              itemCount: widget.observer.transitions.length,
              itemBuilder: (context, index) {
                final transition = widget.observer.transitions[index];
                return Card(
                  child: ListTile(
                    title: Text(
                      transition.transitionText,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(transition.type.title),
                  ),
                );
              },
            );
          },
        ),
      );
}
