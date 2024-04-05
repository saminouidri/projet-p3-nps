import 'dart:ffi';
import 'dart:io';
import 'dart:math';
import 'package:external_path/external_path.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:projet_p3/main.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:sqflite/sqflite.dart';
import 'package:vibration/vibration.dart';
import '../widgets/measurement_card.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  _ScanPageState createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  String qrText = '';
  final TextEditingController _valueController = TextEditingController();
  int currentPageIndex = 0;
  DateTime _selectedDate = DateTime.now();

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  void _presentDatePicker() {
    showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    ).then((pickedDate) {
      if (pickedDate == null) return;
      setState(() {
        _selectedDate = pickedDate;
      });
    });
  }

  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return const MyHomePage(title: 'Clarius Mobilius');
      case 1:
        return const ScanPage();
      default:
        return const MyHomePage(title: 'Clarius Mobilius');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            SizedBox(
              height: 400,
              child: QRView(
                key: qrKey,
                onQRViewCreated: _onQRViewCreated,
                overlay: QrScannerOverlayShape(
                  borderColor: Colors.red,
                  borderRadius: 10,
                  borderLength: 30,
                  borderWidth: 10,
                  cutOutSize: 250,
                ),
              ),
            ),
            Container(
              alignment: Alignment.centerLeft,
              height: 240, // Set the height
              child: qrText.isNotEmpty ? _buildScannedDataCard() : Container(),
            ),
            if (qrText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  children: [
                    Expanded(
                      //entrée de la valeur
                      child: TextField(
                        controller: _valueController,
                        decoration: const InputDecoration(
                          labelText: 'Value',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _submitData,
                      child: const Text('Validate'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Retrieves the variable constraints from the ConfigDB.cdb SQLite database
  Future<Map<String, dynamic>?> fetchVariableConstraints(int iVarID) async {
    // Get the path to the external storage Documents directory
    final documentsDirPath =
        await ExternalPath.getExternalStoragePublicDirectory(
            ExternalPath.DIRECTORY_DOCUMENTS);
    final dbMobiliusDirPath = "$documentsDirPath/DB_mobilius/ConfigDB.cdb";

    try {
      // Open the database
      final Database db = await openDatabase(dbMobiliusDirPath);

      // Query the database for the variable with the matching iVarID
      final List<Map<String, dynamic>> results = await db.query(
        'TBL_VARIABLE',
        where: 'IVARID = ?',
        whereArgs: [iVarID],
      );

      // Ensure the database is closed properly
      await db.close();

      if (results.isNotEmpty) {
        // Check if bIsCompteur is true
        final isCompteur = results.first['BISCOMPTEUR'] == 1;
        if (isCompteur) {
          // If bIsCompteur is true, return NaN values for constraints
          return {
            'rMin': double.nan,
            'rMax': double.nan,
          };
        } else {
          // If bIsCompteur is false, return the found record
          return results.first;
        }
      } else {
        throw Exception('Variable not found');
      }
    } catch (e) {
      print('Error fetching variable constraints: $e');
      return null; // Error occurred
    }
  }

  // Submits data to the TBL_DATAINBOX table
  void _submitData() async {
    try {
      // Extract site and variable IDs
      List<String> dataParts = qrText.split(';');
      int iSiteID = int.parse(dataParts[1]);
      int iVarID = int.parse(dataParts[2]);
      double rValue = double.tryParse(_valueController.text) ?? 0.0;

      // Verify the data before submission
      if (!(await verifyData(iSiteID, iVarID))) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid data, please scan again')),
        );
        return;
      }

      // Fetch variable constraints
      var varConstraints = await fetchVariableConstraints(iVarID);
      double rMin = double.negativeInfinity;
      double rMax = double.infinity;

      // varConstraints is a map that might contain null values for 'rMin' and 'rMax'
      if (varConstraints != null) {
        // Check for null before checking for isNaN
        rMin = varConstraints['rMin'] != null && varConstraints['rMin'].isNaN
            ? double.negativeInfinity
            : varConstraints['rMin'] ??
                double
                    .negativeInfinity; // Fallback to negative infinity if null
        rMax = varConstraints['rMax'] != null && varConstraints['rMax'].isNaN
            ? double.infinity
            : varConstraints['rMax'] ??
                double.infinity; // Fallback to infinity if null
      }

      // Check if the measurement is within constraints
      if (rValue < rMin || rValue > rMax) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Measurement out of bounds')),
        );
        setState(() {
          qrText = '';
          _valueController.clear();
        });
        return;
      }

      // Prepare database path and open the database
      // Get the path to the external storage Documents directory
      final documentsDirPath =
          await ExternalPath.getExternalStoragePublicDirectory(
              ExternalPath.DIRECTORY_DOCUMENTS);
      final dbMobiliusDirPath = "$documentsDirPath/DB_mobilius/MainDB.cdb";
      final Database db = await openDatabase(dbMobiliusDirPath);

      // Insert data into TBL_DATAINBOX
      await db.insert(
        'TBL_DATAINBOX',
        {
          'UTIMESTAMP': DateTime.now().millisecondsSinceEpoch,
          'UUSERTIME': _selectedDate.millisecondsSinceEpoch,
          'ISITEID': iSiteID,
          'IOBJECTID': iVarID, // iVarID <=> iOBJECTID
          'IUSERID': 0, // temp
          'RVALUE': rValue,
          'SVALUE': '', // comment
          'JSVALUE': '',
          'BSTATUS': 0,
          'SINSERTDATE': DateFormat('yyyy-MM-dd HH:mm:ss')
              .format(DateTime.now()), // Format date as text
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data submitted successfully')),
      );
      await db.close();
      setState(() {
        qrText = '';
        _valueController.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting data: $e')),
      );
    }
  }

  Future<bool> verifyData(int iSiteID, int iVarID) async {
    try {
      final documentsDirPath =
          await ExternalPath.getExternalStoragePublicDirectory(
              ExternalPath.DIRECTORY_DOCUMENTS);
      final dbMobiliusDirPath = "$documentsDirPath/DB_mobilius/ConfigDB.cdb";
      final Database db = await openDatabase(dbMobiliusDirPath);

      // Query TBL_SITE to check for iSiteID existence
      List<Map> siteResults = await db.query(
        'TBL_SITE',
        where: 'ISITEID = ?',
        whereArgs: [iSiteID],
        limit: 1,
      );
      bool siteExists = siteResults.isNotEmpty;

      // Query TBL_VARIABLE to check for iVarID existence
      List<Map> varResults = await db.query(
        'TBL_VARIABLE',
        where: 'IVARID = ?',
        whereArgs: [iVarID],
        limit: 1,
      );
      bool varExists = varResults.isNotEmpty;

      // Close the database
      await db.close();

      return siteExists && varExists;
    } catch (e) {
      print('Error verifying data: $e');
      return false;
    }
  }

  Widget _buildScannedDataCard() {
    // Split the qrText into its components
    List<String> dataParts = qrText.split(';');
    if (dataParts.length != 3 || dataParts[0] != 'ClariusDP') {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Invalid QR Code format'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          margin: const EdgeInsets.all(10),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Site: ${dataParts[1]}'),
                Text('Variable: ${dataParts[2]}'),
                //carte d'information
              ],
            ),
          ),
        ),
        MeasurementsCard(
          iSiteID: int.tryParse(dataParts[1]) ?? 0,
          iVarID: int.tryParse(dataParts[2]) ?? 0,
        ),
        ElevatedButton(
          onPressed: _presentDatePicker,
          child: const Text('Choose Date'),
        ),
        // Display the selected date
        Text(
          'Selected Date: ${DateFormat('MM/dd/yyyy').format(_selectedDate)}',
        ),
      ],
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        qrText = scanData.code ?? 'No data';
        Vibration.vibrate(); //feedback haptique
      });
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
