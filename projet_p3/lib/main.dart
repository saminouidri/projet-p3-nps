import 'dart:io';
import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:projet_p3/GDriveAPI/AuthenticatedClient.dart';
import 'package:projet_p3/GDriveAPI/DriveFilePicker.dart';
import 'package:projet_p3/GDriveAPI/GDriveUtils.dart';
import 'package:projet_p3/UI/MainPage.dart';
import 'package:projet_p3/widgets/logs_card.dart';
import 'package:projet_p3/widgets/logs_graph.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'UI/scan.dart';
import 'UI/login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:external_path/external_path.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(MaterialApp(home: MainPage(), theme: darkTheme));
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
      home: const MainPage(),
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
  drive.DriveApi? driveApi; // Make driveApi nullable
  String _email = '';

  @override
  void initState() {
    super.initState();
    signInWithGoogle().then((api) {
      if (api != null) {
        setState(() {
          driveApi = api;
        });
      } else {
        // Handle failed sign-in or prompt user for action
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Errreur de connexion. Veuillez vous connecter.')),
        );
      }
    });
    _loadEmail();
  }

  _loadEmail() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _email = prefs.getString('userEmail') ?? 'Guest';
    });
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

        // ignore: use_build_context_synchronously
        copyFileToDBMobiliusFolder(file, context);

        // Save file ID to sharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString(fileName, fileOnDrive!.id!);
      }
    }
  }

  Future<drive.File?> uploadFileToDrive(String fileName, File file) async {
    var media = drive.Media(file.openRead(), file.lengthSync());
    var driveFile = drive.File()..name = fileName;
    // driveFile.parents = ["DB_mobilius"];
    return await driveApi?.files.create(driveFile, uploadMedia: media);
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
            await driveApi?.files
                .update(fileMetadata, fileId, uploadMedia: media);

            print("File has been successfully updated.");
            // ignore: use_build_context_synchronously
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('File has been successfully updated.')),
            );
          } catch (e) {
            // Handle errors, e.g., print them or display a message
            print("Error updating file: $e");
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Error updating file.')),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Clarius Mobilius'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Bienvenue',
                      style: TextStyle(fontSize: 18, color: Colors.grey)),
                  Text((_email.isEmpty ? 'Guest' : _email),
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 40),
                  const Text('Paramètres',
                      style: TextStyle(fontSize: 18, color: Colors.grey)),
                  const SizedBox(height: 20),
                  const Text('Charger les bases de données'),
                  ElevatedButton(
                    onPressed: loadDatabases,
                    child: const Text('Sélectionner les fichiers'),
                  ),
                  const SizedBox(height: 10),
                  //italic info text
                  const Text(
                      'Copie local des bases de données et televersement sur GDrive pour la 1ère mise en route.',
                      style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Colors.blue)),
                  const SizedBox(height: 20),
                  const Text('Synchoniser les bases de données'),
                  ElevatedButton(
                    onPressed: synchronizeDatabases,
                    child: const Text('Synchoniser'),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                      'Synchronisation entre les données locales et GDrive.',
                      style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Colors.blue)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
