// measurements_card.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class MeasurementsCard extends StatelessWidget {
  final int iSiteID;
  final int iVarID;

  const MeasurementsCard({
    Key? key,
    required this.iSiteID,
    required this.iVarID,
  }) : super(key: key);

  Future<List<Map<String, dynamic>>> fetchLastThreeMeasurements() async {
    var querySnapshot = await FirebaseFirestore.instance
        .collection('TBL_DATAINBOX')
        .where('iVarID', isEqualTo: iVarID)
        .where('iSiteID', isEqualTo: iSiteID)
        .orderBy('dUserTime', descending: true)
        .limit(3)
        .get();

    //trie les données par date

    return querySnapshot.docs.map((doc) => doc.data()).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchLastThreeMeasurements(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }

        if (snapshot.hasError) {
          return Text("Error: ${snapshot.error}");
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Text("No measurements found");
        }

        List<Map<String, dynamic>> measurements = snapshot.data!;

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          margin: const EdgeInsets.all(10),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: measurements.map((measurement) {
                DateTime date =
                    (measurement['dUserTime'] as Timestamp).toDate(); //date
                double value = measurement['rValue'];
                return Text(
                    'Measurement: $value, Date: ${DateFormat.yMd().format(date)}');
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}
