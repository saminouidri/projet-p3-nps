import 'dart:ffi';
import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:projet_p3/main.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
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

  //Recupère les contraintes du paramètre
  Future<Map<String, dynamic>?> fetchVariableConstraints(int iVarID) async {
    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('TBL_VARIABLE')
          .where('iVarID', isEqualTo: iVarID)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.data();
      } else {
        throw Exception('Variable not found');
      }
    } catch (e) {
      print('Error fetching variable constraints: $e');
      return null; // Error occurred
    }
  }

  //Soumet les données dans la table TBL_DATAINBOX
  void _submitData() async {
    try {
      // Extract parameter ID and measurement value
      List<String> dataParts = qrText.split(';');
      int iSiteID;
      int iVarID;

      try {
        iSiteID = int.parse(dataParts[1]);
        iVarID = int.parse(dataParts[2]);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid site or variable ID')),
        );
        return;
      }
      double rValue = double.tryParse(_valueController.text) ?? 0.0;

      // Fetch parameter constraints
      var varConstraints = await fetchVariableConstraints(iVarID);
      if (varConstraints != null) {
        double rMin = (varConstraints['rMin'] as num?)?.toDouble() ??
            double.negativeInfinity;
        double rMax =
            (varConstraints['rMax'] as num?)?.toDouble() ?? double.infinity;

        // Check if the measurement is within constraints
        if (rValue < rMin || rValue > rMax) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Measurement out of bounds')),
          );
          return;
        }
      }

      // Proceed with data submission
      await FirebaseFirestore.instance.collection('TBL_DATAINBOX').add({
        'dTimeStamp': Timestamp.now(),
        'dUserTime': Timestamp.fromDate(_selectedDate),
        'iVarID': iVarID,
        'iSiteID': iSiteID,
        'iUserID': 0,
        'jsValue': '',
        'rValue': rValue,
        'sValue': '',
        'bStatus': false,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data submitted successfully')),
      );
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
      // Check if the post exists in TBL_POST
      var postSnapshot = await FirebaseFirestore.instance
          .collection('TBL_SITE')
          .where('iSiteID', isEqualTo: iSiteID)
          .limit(1)
          .get();
      bool postExists = postSnapshot.docs.isNotEmpty;

      // Check if the variable exists in TBL_VARIABLE
      var parameterSnapshot = await FirebaseFirestore.instance
          .collection('TBL_VARIABLE')
          .where('iVarID', isEqualTo: iVarID)
          .limit(1)
          .get();
      bool varExists = parameterSnapshot.docs.isNotEmpty;

      return postExists && varExists;
    } catch (e) {
      print('Error verifying data: $e');
      return false;
    }
  }

  Widget _buildScannedDataCard() {
    // Split the qrText into its components
    List<String> dataParts = qrText.split(';');
    if (dataParts.length != 4 || dataParts[0] != 'ClariusDP') {
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
