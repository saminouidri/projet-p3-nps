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

// Retrieves the variable constraints from the ConfigDB.cdb SQLite database
Future<Map<String, dynamic>?> fetchVariableConstraints(int iVarID) async {
  // Get the path to the external storage Documents directory
  final documentsDirPath = await ExternalPath.getExternalStoragePublicDirectory(
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
      throw Exception('Variable pas trouvé.');
    }
  } catch (e) {
    print('Erreur lors de la recuperation de limites: $e');
    return null; // Error occurred
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

Future<Map<String, String>> fetchSiteAndVariableNames(
    int iSiteID, int iVarID) async {
  //fetch variable and site name from the database
  final documentsDirPath = await ExternalPath.getExternalStoragePublicDirectory(
      ExternalPath.DIRECTORY_DOCUMENTS);
  final dbMobiliusDirPath = "$documentsDirPath/DB_mobilius/ConfigDB.cdb";

  // Open the database
  Database db = await openDatabase(dbMobiliusDirPath);

  try {
    // Fetch site name
    List<Map<String, dynamic>> siteQuery = await db.query(
      'TBL_SITE',
      columns: ['SSITENAME'],
      where: 'ISITEID = ?',
      whereArgs: [iSiteID],
    );
    String siteName = siteQuery.isNotEmpty
        ? siteQuery.first['SSITENAME'] as String
        : 'Unknown';

    // Fetch variable name
    List<Map<String, dynamic>> variableQuery = await db.query(
      'TBL_VARIABLE',
      columns: ['SVARNAME'],
      where: 'IVARID = ?',
      whereArgs: [iVarID],
    );
    String variableName = variableQuery.isNotEmpty
        ? variableQuery.first['SVARNAME'] as String
        : 'Unknown';

    return {
      'siteName': siteName,
      'variableName': variableName,
    };
  } finally {
    // Ensure the database is closed when done
    await db.close();
  }
}
