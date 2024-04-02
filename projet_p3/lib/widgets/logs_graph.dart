import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class LogGraph extends StatelessWidget {
  final List<DocumentSnapshot> documents;

  const LogGraph({Key? key, required this.documents}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double maxY = 0.0;

    double y = 0.0;

    // date de demarrage dynamique
    // On calcule la date de depart en fonction de la date la plus ancienne dans la table
    DateTime getStartDate(List<DocumentSnapshot> documents) {
      DateTime earliest = DateTime.now();
      for (var doc in documents) {
        var data = doc.data() as Map<String, dynamic>;
        Timestamp? timestamp = data['dTimeStamp'];
        y = data['rAverageDelta']?.toDouble() ?? 0.0;
        if (timestamp != null) {
          DateTime date = timestamp.toDate();
          if (date.isBefore(earliest)) {
            earliest = date;
          }
        }
        if (y > maxY) {
          maxY = y; //definit le maximum pour l'echelle du graph
        }
      }
      return earliest;
    }

    DateTime startDate = getStartDate(documents);

    List<FlSpot> spots = documents
        .map((doc) {
          var data = doc.data() as Map<String, dynamic>;
          double y =
              data['rAverageDelta']?.toDouble() ?? 0.0; //redeclaration de y
          Timestamp? timestamp = data['dStartDT'];
          if (timestamp == null) {
            return null; // Skip if no timestamp
          }
          DateTime x = timestamp.toDate();
          int daysSinceStart = x.difference(startDate).inDays;
          return FlSpot(daysSinceStart.toDouble(), y);
        })
        .where((spot) => spot != null)
        .cast<FlSpot>()
        .toList(); //cast pour transformer en liste

    print('spots: $spots');
    print('maxY: $maxY');

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      margin: const EdgeInsets.all(10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: maxY,
            gridData: FlGridData(show: true),
            titlesData: FlTitlesData(
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (double value, TitleMeta meta) {
                    DateTime date =
                        startDate.add(Duration(days: value.toInt()));
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      space: 8.0,
                      child: Text(DateFormat('MM/dd').format(date)),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: true),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: false,
                barWidth: 0,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
