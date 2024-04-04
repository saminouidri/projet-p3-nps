import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/src/client.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:io' show Platform;

final GoogleSignIn googleSignIn = GoogleSignIn(
  scopes: <String>[drive.DriveApi.driveFileScope],
);

Future<drive.DriveApi?> signInWithGoogle() async {
  try {
    final account = await googleSignIn.signIn();
    final authHeaders = await account!.authHeaders;
    final authenticateClient = AuthenticatedClient(authHeaders);
    return drive.DriveApi(authenticateClient as Client);
  } catch (error) {
    print("Error signing in with Google: $error");
    return null;
  }
}

class AuthenticatedClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  AuthenticatedClient(this._headers);

  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return _client.send(request..headers.addAll(_headers));
  }
}
