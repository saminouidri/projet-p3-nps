import 'dart:io';
import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:projet_p3/GDriveAPI/AuthenticatedClient.dart';
import 'package:projet_p3/GDriveAPI/DriveFilePicker.dart';
import 'package:projet_p3/UI/MainPage.dart';
import 'package:projet_p3/widgets/logs_card.dart';
import 'package:projet_p3/widgets/logs_graph.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'UI/scan.dart';
import 'UI/login.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:external_path/external_path.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(MaterialApp(home: MyHomePage(title: 'Clarius Mobilius')));
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
      home: const MyHomePage(
        title: 'Clarius Mobilius',
      ),
      routes: {
        '/home': (context) => const MyHomePage(title: 'Clarius Mobilius'),
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
  late drive.DriveApi driveApi;

  @override
  void initState() {
    super.initState();
    signInWithGoogle().then((api) {
      setState(() {
        driveApi = api!;
      });
    });
  }

  // Function to copy file to the "DB_mobilius" folder in the Documents directory
  Future<void> copyFileToDBMobiliusFolder(File file) async {
    try {
      // Get the path to the external storage Documents directory
      final documentsDirPath =
          await ExternalPath.getExternalStoragePublicDirectory(
              ExternalPath.DIRECTORY_DOCUMENTS);
      final dbMobiliusDirPath = "$documentsDirPath/DB_mobilius";

      // Check if the "DB_mobilius" directory exists, create if not
      final dbMobiliusDirectory = Directory(dbMobiliusDirPath);
      if (!await dbMobiliusDirectory.exists()) {
        await dbMobiliusDirectory.create(recursive: true);
      }

      // Construct the path to save the file in the "DB_mobilius" directory
      final fileName = path
          .basename(file.path); // Extract the file name from the original path
      final newPath = path.join(dbMobiliusDirPath, fileName);

      // Copy the file to the new path
      await file.copy(newPath);

      print("File copied to $newPath");
    } catch (e) {
      print("Error copying file to DB_mobilius folder: $e");
    }
  }

  Future<void> loadDatabases() async {
    // Pick two files from local storage
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null && result.files.length == 2) {
      for (var pickedFile in result.files) {
        File file = File(pickedFile.path!);
        String fileName = pickedFile.name;

        // Upload file to Google Drive and save file ID
        var fileOnDrive = await uploadFileToDrive(fileName, file);

        copyFileToDBMobiliusFolder(file);

        // Save file ID to sharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString(fileName, fileOnDrive.id!);
      }
    }
  }

  Future<drive.File> uploadFileToDrive(String fileName, File file) async {
    var media = drive.Media(file.openRead(), file.lengthSync());
    var driveFile = drive.File()..name = fileName;
    // driveFile.parents = ["DB_mobilius"];
    return await driveApi.files.create(driveFile, uploadMedia: media);
  }

  Future<void> synchronizeDatabases() async {
    // Retrieve local files and their IDs from sharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final directory = await ExternalPath.getExternalStoragePublicDirectory(
        ExternalPath.DIRECTORY_DOCUMENTS);
    final dbDirectory = Directory("$directory/DB_mobilius");

    if (dbDirectory.existsSync()) {
      List<FileSystemEntity> files = dbDirectory.listSync();
      for (var fileEntity in files) {
        File localFile = File(fileEntity.path);
        String fileName = localFile.uri.pathSegments.last;
        String? fileId = prefs.getString(fileName);

        if (fileId != null) {
          // Create an empty File object for the metadata
          var fileMetadata = drive.File();

          // Prepare the media (file content) to be uploaded
          var media = drive.Media(localFile.openRead(), localFile.lengthSync());

          try {
            // Call the update method with the empty metadata and the media
            await driveApi.files
                .update(fileMetadata, fileId, uploadMedia: media);

            print("File has been successfully updated.");
          } catch (e) {
            // Handle errors, e.g., print them or display a message
            print("Error updating file: $e");
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    String username = user != null ? user.email ?? 'Anonymous User' : 'Guest';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Clarius Mobilius'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Welcome',
                    style: TextStyle(fontSize: 18, color: Colors.grey)),
                Text(username,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                const Text('Load Databases'),
                ElevatedButton(
                  onPressed: loadDatabases,
                  child: const Text('Pick Files and Upload'),
                ),
                const SizedBox(height: 20),
                const Text('Synchronize Databases'),
                ElevatedButton(
                  onPressed: synchronizeDatabases,
                  child: const Text('Sync Files with GDrive'),
                ),
              ],
            ),
          ),
        ],
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
