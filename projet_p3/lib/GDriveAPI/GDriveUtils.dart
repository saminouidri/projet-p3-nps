import 'dart:io';
import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:projet_p3/GDriveAPI/AuthenticatedClient.dart';
import 'package:projet_p3/GDriveAPI/DriveFilePicker.dart';
import 'package:projet_p3/UI/MainPage.dart';
import 'package:projet_p3/i18n/app_localization.dart';
import 'package:projet_p3/widgets/logs_card.dart';
import 'package:projet_p3/widgets/logs_graph.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:external_path/external_path.dart';

// Function to copy file to the "DB_mobilius" folder in the Documents directory
Future<void> copyFileToDBMobiliusFolder(File file, BuildContext context) async {
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              AppLocalizations.of(context).translate('fileCopiedSuccess') ??
                  'File copied successfully.' + ' $newPath')),
    );
  } catch (e) {
    print("Error copying file to DB_mobilius folder: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              AppLocalizations.of(context).translate('errorCopyingFile') ??
                  'An error has occured')),
    );
  }
}
