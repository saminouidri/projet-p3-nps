import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:file_picker/file_picker.dart';

class DriveFilePicker extends StatefulWidget {
  final drive.DriveApi driveApi;

  const DriveFilePicker({Key? key, required this.driveApi}) : super(key: key);

  @override
  _DriveFilePickerState createState() => _DriveFilePickerState();
}

class _DriveFilePickerState extends State<DriveFilePicker> {
  Future<void> _pickAndUploadFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      File file = File(result.files.single.path!);
      String fileName = result.files.single.name;
      // Prepare the file for uploading
      var media = drive.Media(file.openRead(), file.lengthSync());
      var driveFile = drive.File();
      driveFile.name = fileName;
      // Upload file
      try {
        var createdFile =
            await widget.driveApi.files.create(driveFile, uploadMedia: media);
        _showUploadSuccessDialog();
        // File uploaded successfully, now download it
        _downloadFile(createdFile.id, fileName);
      } catch (e) {
        _showErrorDialog(e.toString());
      }
    } else {
      // User canceled the picker
    }
  }

  void _downloadFile(String? fileId, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = "${directory.path}/$fileName";
    final saveFile = File(filePath);
    // Download file
    try {
      var media = await widget.driveApi.files.get(fileId!,
          downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;
      List<int> dataStore = [];
      media.stream.listen((data) {
        dataStore.insertAll(dataStore.length, data);
      }, onDone: () {
        saveFile.writeAsBytes(dataStore).then((file) {
          // File download successful
          _showDownloadSuccessDialog(filePath);
        });
      }, onError: (error) {
        _showErrorDialog("Error downloading file: $error");
      });
    } catch (e) {
      _showErrorDialog("Error downloading file: $e");
    }
  }

  void _showDownloadSuccessDialog(String filePath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Download Success'),
          content: Text('File downloaded successfully to $filePath.'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  void _showUploadSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Success'),
          content: const Text('File uploaded successfully to Google Drive.'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload File to Google Drive'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: _pickAndUploadFile,
          child: const Text('Pick and Upload File'),
        ),
      ),
    );
  }
}
