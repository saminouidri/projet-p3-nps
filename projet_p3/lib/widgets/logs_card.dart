// logs_card.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class LogsCard extends StatelessWidget {
  final List<DocumentSnapshot> documents;

  const LogsCard({Key? key, required this.documents}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      margin: const EdgeInsets.all(10),
      child: SizedBox(
        height: 300,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text('Start Time', style: TextStyle(fontSize: 12)),
                    Spacer(flex: 1),
                    Text('Stop Time', style: TextStyle(fontSize: 12)),
                    Spacer(flex: 1),
                    Text('Average Delta', style: TextStyle(fontSize: 12)),
                    //texte de la colonne
                    //Text('Percentage Completed', TODO
                    //    style: TextStyle(fontSize: 12)),
                  ],
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: documents.length,
                  itemBuilder: (context, index) {
                    var documentData =
                        documents[index].data() as Map<String, dynamic>;
                    DateTime dStartDT =
                        (documentData['dStartDT'] as Timestamp).toDate();
                    DateTime dEndDT =
                        (documentData['dEndDT'] as Timestamp).toDate();
                    double rAverageDelta =
                        documentData['rAverageDelta'].toDouble();
                    double rPerCompleted =
                        documentData['rPerCompleted'].toDouble();

                    String formattedStartDT =
                        DateFormat('MM.dd HH:mm').format(dStartDT);
                    String formattedEndDT =
                        DateFormat('MM.dd HH:mm').format(dEndDT);

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text(formattedStartDT),
                        Spacer(flex: 1),
                        Text(formattedEndDT),
                        Spacer(flex: 1),
                        Text('$rAverageDelta'),
                        //texte du body
                        //Text('$rPerCompleted%'), TODO
                      ],
                    );
                  },
                ),
                const Padding(padding: EdgeInsets.all(16)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
