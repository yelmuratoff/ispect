import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';

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
    return MaterialApp(
      builder: (context, child) => DraggableCircularMenu(
        toggleButtonColor: Colors.pink,
        curve: Curves.fastEaseInToSlowEaseOut,
        reverseCurve: Curves.fastEaseInToSlowEaseOut,
        items: [
          CircularMenuItem(
              icon: Icons.home,
              boxShadow: [],
              color: Colors.green,
              onTap: () {
                setState(() {
                  _color = Colors.green;
                  _colorName = 'Green';
                });
              }),
          CircularMenuItem(
              icon: Icons.search,
              boxShadow: [],
              color: Colors.blue,
              onTap: () {
                setState(() {
                  _color = Colors.blue;
                  _colorName = 'Blue';
                });
              }),
          CircularMenuItem(
              icon: Icons.settings,
              boxShadow: [],
              color: Colors.orange,
              onTap: () {
                setState(() {
                  _color = Colors.orange;
                  _colorName = 'Orange';
                });
              }),
          CircularMenuItem(
              icon: Icons.chat,
              boxShadow: [],
              color: Colors.purple,
              onTap: () {
                setState(() {
                  _color = Colors.purple;
                  _colorName = 'Purple';
                });
              }),
          CircularMenuItem(
              icon: Icons.notifications,
              boxShadow: [],
              color: Colors.brown,
              onTap: () {
                setState(() {
                  _color = Colors.brown;
                  _colorName = 'Brown';
                });
              })
        ],
        child: child!,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Circular Draggable button'),
        ),
        body: Stack(
          children: [
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
