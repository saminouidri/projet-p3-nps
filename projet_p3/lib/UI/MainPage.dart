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
    const MyHomePage(title: 'Projet P3'), // Index 0
    const ScanPage(), // Index 1
  ];

  bool isRoundActive = false;
  DateTime? startTimestamp;
  DateTime? stopTimestamp;

  Future<void> saveRoundData(DateTime startDate, DateTime endDate) async {
    try {
      // Recherche des documents correspondant à la période
      var querySnapshot = await FirebaseFirestore.instance
          .collection('TBL_DATAINBOX')
          .where('dTimeStamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('dTimeStamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      // Insertion du document dans la collection TBL_LOGS
      await FirebaseFirestore.instance.collection('TBL_LOGS').add({
        'dStartDT': Timestamp.fromDate(startDate),
        'dEndDT': Timestamp.fromDate(endDate),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Round saved successfully!'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save round data: $e'),
        ),
      );
    }
  }

  void toggleRound() {
    setState(() {
      if (isRoundActive) {
        stopTimestamp = DateTime.now();
        saveRoundData(startTimestamp!, stopTimestamp!);
      } else {
        startTimestamp = DateTime.now();
      }
      isRoundActive = !isRoundActive;
    });
  }

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
      floatingActionButton: currentPageIndex == 0
          ? FloatingActionButton(
              onPressed: toggleRound,
              tooltip: isRoundActive ? 'Stop Round' : 'Start Round',
              backgroundColor: isRoundActive ? Colors.red : Colors.green,
              child: Icon(isRoundActive ? Icons.stop : Icons.play_arrow),
            )
          : null, // Only show FAB on Home page (index 0)
    );
  }
}
