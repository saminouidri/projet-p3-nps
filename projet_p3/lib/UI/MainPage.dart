import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:projet_p3/UI/scan.dart';
import 'package:projet_p3/main.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int currentPageIndex = 0;

  final List<Widget> _pages = [
    const MyHomePage(title: 'Clarius Mobilius'), // Index 0
    const ScanPage(), // Index 1
  ];

  bool isRoundActive = false;
  DateTime? startTimestamp;
  DateTime? stopTimestamp;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[currentPageIndex], // Display the selected page

      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        selectedIndex: currentPageIndex,
        destinations: const <Widget>[
          NavigationDestination(
            selectedIcon: Icon(Icons.home),
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Badge(child: Icon(Icons.qr_code_scanner)),
            label: 'Scan',
          ),
        ],
      ),
    );
  }
}
