import 'package:flutter/material.dart';

/// The CustomNavigationBar class is a StatefulWidget that represents a custom navigation bar with a
/// selected index.
class CustomNavigationBar extends StatefulWidget {
  final int selectedIndex;

  const CustomNavigationBar({super.key, this.selectedIndex = 0});

  @override
  _CustomNavigationBarState createState() => _CustomNavigationBarState();
}

/// The `_CustomNavigationBarState` class is a stateful widget that represents a custom bottom
/// navigation bar in Dart, allowing users to navigate between different screens.
class _CustomNavigationBarState extends State<CustomNavigationBar> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/scan');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.scanner),
          label: 'Scan',
        ),
      ],
      currentIndex: _selectedIndex,
      selectedItemColor: const Color.fromARGB(255, 255, 255, 255),
      unselectedItemColor: const Color.fromARGB(255, 255, 255, 255),
      onTap: _onItemTapped,
    );
  }
}
