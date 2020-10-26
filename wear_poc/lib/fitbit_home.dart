import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class FitbitHome extends StatefulWidget {
  @override
  _FitbitHomeState createState() => _FitbitHomeState();
}

class _FitbitHomeState extends State<FitbitHome> {
  HttpServer server;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fitbit Data'),
      ),
      body: Center(
        child: RaisedButton(
          onPressed: () {
            //TODO navigate to fitbit authentication page
//          authenticate();
            authenticateUser(context);
          },
          child: Text('Fetch Data'),
        ),
      ),
    );
  }

  Future<void> loadUserInformation(String accessToken) async {
   /* String clientId = "22BZMN";
    String clientSecret =
        "e8c3fc28330e623bb8eb1a01480165ce";
    String basicAuth =
        "Basic " + base64Encode(utf8.encode('$clientId:$clientSecret'));*/

    final response = await http.get(
      "https://api.fitbit.com/1/user/-/profile.json",
      headers: {
        "Authorization": "Bearer "+ accessToken,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
    );

    print('User Response: ${response.body}');

    print("user response code: " + response.statusCode.toString());
    if (response.statusCode == 200) {
      print('Successfully fetched user info !');
    } else {
       print("Authentication failed");
//      authResult = false;
    }
  }

/*  void authenticate() async {
    // Present the dialog to the user
    print('Before Authentication');
    final result = await FlutterWebAuth.authenticate(
      url:
          "https://www.fitbit.com/oauth2/authorize?response_type=token&client_id=22BZMN&expires_in=2592000&scope=activity%20nutrition%20heartrate%20location%20nutrition%20profile%20settings%20sleep%20social%20weight&redirect_uri=https://tekfriday.com&prompt=login",
      //TODO: add &prompt=login to shwo login screen every time.
      callbackUrlScheme: "tekfriday",
    );
  }*/

  Future<Stream<String>> accessCodeServer() async {
    print('Inside accessCodeServer() method');
    final StreamController<String> onCode = new StreamController();
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 8080);
    server.listen((HttpRequest request) async {
//      // print("Server started");
      final String code = request.uri.queryParameters["code"];
      print('The code: $code');
//      // print(request.uri.pathSegments);
      request.response
        ..statusCode = 200
        ..headers.set("Content-Type", ContentType.html.mimeType)
        ..write(
            '<html><meta name="viewport" content="width=device-width, initial-scale=1.0"><body> <h2 style="text-align: center; position: absolute; top: 50%; left: 0: right: 0">Welcome to Fritter</h2><h3>You can close this window<script type="javascript">window.close()</script> </h3></body></html>');
      await request.response.close();
      await server.close(force: true);
      onCode.add(code);
      await onCode.close();
    });
    return onCode.stream;
  }

  Future<bool> performAuthentication() async {
    print('Inside performAuthentication() method');
    bool authResult = true;
    if (server != null) {
      await server.close(force: true);
    }
//    await _storageHelper.clearStorage();
    // print("*** Performing authentication ****");
    // start a new instance of the server that listens to localhost requests
    Stream<String> onCode = await accessCodeServer();

    // server returns the first access_code it receives

    final String accessCode = await onCode.first;
    print('Access Code: $accessCode');
    print("local host response");
    if (accessCode == null) {
      print("Access code called on null");
      authResult = false;
    }

    // now we use this code to obtain authentication token and other data

    String clientId = "22BZMN";
    String clientSecret =
        "e8c3fc28330e623bb8eb1a01480165ce"; // blank for unknown clients like apps

    String basicAuth =
        "Basic " + base64Encode(utf8.encode('$clientId:$clientSecret'));
    print('Auth: $basicAuth');
    final response = await http.post(
      "https://api.fitbit.com/oauth2/token",
      headers: {
        "Authorization": basicAuth,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body:
          "grant_type=authorization_code&code=$accessCode&redirect_uri=http://localhost:8080/&prompt=login",
    );
print('Response: ${response.body}');
 print("New authentication response code: " + response.statusCode.toString());
    if (response.statusCode == 200) {
      Map<String, dynamic> map = json.decode(response.body);
      String accessToken = map['access_token'];
      print('Access Token: $accessToken');
      String refreshToken = map['refresh_token'];
      print('Refresh Token: $refreshToken');
      /*  await _storageHelper.updateCredentials(map['access_token'],
          map['refresh_token'], DateTime.now().toIso8601String(), true);*/
      print('authentication: token stored to secure storage');
      await loadUserInformation(accessToken);
      authResult = true;
    } else {
      print("Authentication failed");
      authResult = false;
    }
    return authResult;
  }

  Future<void> authenticateUser(BuildContext context) async {
    await launch(
        "https://www.fitbit.com/oauth2/authorize?response_type=code&client_id=22BZMN&redirect_uri=http://localhost:8080/&scope=activity%20nutrition%20heartrate%20location%20nutrition%20profile%20settings%20sleep%20social%20weight");

    bool res = await performAuthentication();
    print("final res: " + res.toString());
    if (res) {
//      Navigator.of(context).pop();
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      Navigator.of(context).pop();
    }
  }
}
