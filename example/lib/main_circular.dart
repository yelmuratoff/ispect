import 'package:flutter/material.dart';
import 'package:ispect_example/circular_menu/item.dart';
import 'package:ispect_example/circular_menu/menu.dart';

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
      builder: (context, child) => DraggableCircularMenu(
        toggleButtonColor: Colors.pink,
        curve: Curves.fastEaseInToSlowEaseOut,
        reverseCurve: Curves.fastEaseInToSlowEaseOut,
        items: [
          CircularMenuItem(
              icon: Icons.home,
              color: Colors.green,
              onTap: () {
                setState(() {
                  _color = Colors.green;
                  _colorName = 'Green';
                });
              }),
          CircularMenuItem(
              icon: Icons.search,
              color: Colors.blue,
              onTap: () {
                setState(() {
                  _color = Colors.blue;
                  _colorName = 'Blue';
                });
              }),
          CircularMenuItem(
              icon: Icons.settings,
              color: Colors.orange,
              onTap: () {
                setState(() {
                  _color = Colors.orange;
                  _colorName = 'Orange';
                });
              }),
          CircularMenuItem(
              icon: Icons.chat,
              color: Colors.purple,
              onTap: () {
                setState(() {
                  _color = Colors.purple;
                  _colorName = 'Purple';
                });
              }),
          CircularMenuItem(
              icon: Icons.notifications,
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
