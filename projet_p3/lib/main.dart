import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:projet_p3/UI/MainPage.dart';
import 'package:projet_p3/widgets/logs_card.dart';
import 'package:projet_p3/widgets/logs_graph.dart';
import 'UI/scan.dart';
import 'UI/login.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MaterialApp(home: const AuthWrapper(), theme: darkTheme));
}

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: Colors.blueGrey,
  colorScheme: const ColorScheme.dark(
    secondary: Colors.cyanAccent,
  ),
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  //
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clarius Mobilius',
      home: const AuthWrapper(),
      routes: {
        '/home': (context) => const MyHomePage(title: 'Projet P3'),
        '/scan': (context) => const ScanPage(),
        '/login': (context) => const LoginPage(),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    String username = user != null ? user.email ?? 'Anonymous User' : 'Guest';
    int currentPageIndex = 0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Clarius Mobilius'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('TBL_LOGS')
            .snapshots(), //recupere les donnees de la table TBL_LOGS
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // Check for data
          if (snapshot.hasData) {
            List<DocumentSnapshot> documents = snapshot.data!.docs;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome', // The smaller 'Welcome' text
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      Text(
                        username,
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                LogsCard(documents: documents),
                /*
                Expanded(
                  child: LogGraph(documents: documents),
                ),
                */
              ],
            );
          } else {
            return const Center(child: Text('No Data Available'));
          }
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  //sign out function
  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    // Call the sign out function
    _signOut();
    // Directly return the LoginPage widget
    debugPrint('============================User signed out');
    return const LoginPage();
  }
}
