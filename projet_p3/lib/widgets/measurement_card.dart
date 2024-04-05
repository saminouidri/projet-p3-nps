import 'package:external_path/external_path.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';

class MeasurementsCard extends StatelessWidget {
  final int iSiteID;
  final int iVarID;

  const MeasurementsCard({
    Key? key,
    required this.iSiteID,
    required this.iVarID,
  }) : super(key: key);

  Future<List<Map<String, dynamic>>> fetchLastThreeMeasurements() async {
    final documentsDirPath =
        await ExternalPath.getExternalStoragePublicDirectory(
            ExternalPath.DIRECTORY_DOCUMENTS);
    final dbMobiliusDirPath = "$documentsDirPath/DB_mobilius/MainDB.cdb";
    final Database db = await openDatabase(dbMobiliusDirPath);

    // Assuming 'dUserTime' is stored as INTEGER (Unix timestamp) in the SQLite database
    List<Map<String, dynamic>> measurements = await db.query(
      'TBL_DATAINBOX',
      where: 'IOBJECTID = ? AND ISITEID = ?',
      whereArgs: [iVarID, iSiteID],
      orderBy: 'UUSERTIME DESC',
      limit: 3,
    );

    await db.close();
    return measurements;
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
                // Convert UNIX timestamp to DateTime
                DateTime date = DateTime.fromMillisecondsSinceEpoch(
                    measurement['UUSERTIME'] * 1000);
                double value = measurement['RVALUE'];
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
