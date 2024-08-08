import 'package:flutter/material.dart';
import 'package:ispect_example/panel/panel.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _colorName = 'No';
  Color _color = Colors.black;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    return MaterialApp(
      builder: (context, child) => DraggableButtonPanel(
        options: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              setState(() {
                _color = Colors.green;
                _colorName = 'Green';
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              setState(() {
                _color = Colors.blue;
                _colorName = 'Blue';
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              setState(() {
                _color = Colors.orange;
                _colorName = 'Orange';
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.chat),
            onPressed: () {
              setState(() {
                _color = Colors.purple;
                _colorName = 'Purple';
              });
            },
          ),
        ],
        child: child!,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter Circular Menu'),
        ),
        body: Stack(
          children: [
            Positioned(
              left: (screenSize.width / 2) - 40,
              top: screenSize.height / 2,
              child: Container(
                color: Colors.red.withOpacity(0.5),
                height: 80,
                width: 80,
              ),
            ),
            Center(
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.black, fontSize: 28),
                  children: <TextSpan>[
                    TextSpan(
                      text: _colorName,
                      style: TextStyle(color: _color, fontWeight: FontWeight.bold),
                    ),
                    const TextSpan(text: ' button is clicked.'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
