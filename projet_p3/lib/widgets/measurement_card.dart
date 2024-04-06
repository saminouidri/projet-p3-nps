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
                // Assume UUSERTIME is in seconds; adjust if it's already in milliseconds
                int timestamp = measurement['UUSERTIME'];
                // Create a DateTime object only if the timestamp is within a reasonable range
                DateTime? date;
                if (timestamp > 0 &&
                    timestamp <
                        DateTime.now()
                                .add(Duration(days: 365 * 20))
                                .millisecondsSinceEpoch /
                            1000) {
                  date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
                }

                double value = measurement['RVALUE'];
                // Use a default date string if the date is null
                String dateString = date != null
                    ? DateFormat.yMd().format(date)
                    : "Invalid Date";
                return Text('Measurement: $value, Date: $dateString');
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}
