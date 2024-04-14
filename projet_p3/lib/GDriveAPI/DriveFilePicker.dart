import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:projet_p3/i18n/app_localization.dart';

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
        _showErrorDialog(
            AppLocalizations.of(context).translate('downloadErrorMessage') ??
                'An error has occured' + "$error");
      });
    } catch (e) {
      _showErrorDialog(
          AppLocalizations.of(context).translate('downloadErrorMessage') ??
              'An error has occured' + "$e");
    }
  }

  void _showDownloadSuccessDialog(String filePath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
              AppLocalizations.of(context).translate('downloadSuccessTitle') ??
                  'Sucess'),
          content: Text(AppLocalizations.of(context)
                  .translate('downloadSuccessMessage') ??
              'Successfully downloaded to ' + '$filePath.'),
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
          title: Text(
              AppLocalizations.of(context).translate('uploadSuccessTitle') ??
                  'Success'),
          content: Text(
              AppLocalizations.of(context).translate('uploadSuccessMessage') ??
                  'File uploaded successfully to Google Drive.'),
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
        title: Text(AppLocalizations.of(context).translate('uploadToGDrive') ??
            'Upload to Google Drive'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: _pickAndUploadFile,
          child: Text(
              AppLocalizations.of(context).translate('pickAndUploadFile') ??
                  'Pick and Upload File'),
        ),
      ),
    );
  }
}
