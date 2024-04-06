import 'dart:ffi';
import 'dart:io';
import 'dart:math';
import 'package:external_path/external_path.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:projet_p3/UI/scanUtils.dart';
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
              child: qrText.isNotEmpty
                  ? FutureBuilder<Widget>(
                      future: _buildScannedDataCard(),
                      builder: (BuildContext context,
                          AsyncSnapshot<Widget> snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          // Return a loader widget or an empty container while waiting
                          return Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          // Handle any errors
                          return Text('Error: ${snapshot.error}');
                        } else {
                          // Return the fully built widget
                          return snapshot.data ??
                              Container(); // Fallback to an empty container if snapshot.data is null
                        }
                      },
                    )
                  : Container(), // Fallback widget when qrText.isEmpty is true
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
                          labelText: 'Valeur...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _submitData,
                      child: const Text('Valider'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
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
          const SnackBar(
              content: Text('Erreur : Site et/ou variable inconnu(e)')),
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
          SnackBar(content: Text('Mesure hors limites')),
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
        const SnackBar(content: Text('Donnée soumise avec succès')),
      );
      await db.close();
      setState(() {
        qrText = '';
        _valueController.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'envoi de donnée: $e')),
      );
    }
  }

  Future<Widget> _buildScannedDataCard() async {
    // Split the qrText into its components
    List<String> dataParts = qrText.split(';');
    if ((dataParts.length > 3 || dataParts.length < 2) ||
        !dataParts[0].contains('Clarius')) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Format de code QR invalide.'),
        ),
      );
    }

    Map<String, String> names = await fetchSiteAndVariableNames(
        int.parse(dataParts[1]), int.parse(dataParts[2]));

    return SingleChildScrollView(
      child: Column(
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
                  Text('Site: ${names['siteName']}'),
                  Text('Variable: ${names['variableName']}'),
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
            child: const Text('Choisir une date de mesure'),
          ),
          // Display the selected date
          Text(
            'Date selectionnée: ${DateFormat('MM/dd/yyyy').format(_selectedDate)}',
          ),
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        qrText = scanData.code ?? 'Pas de données trouvées.';
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
