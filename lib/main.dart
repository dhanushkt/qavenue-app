import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:flutter_offline/flutter_offline.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share/share.dart';

void main() => runApp(MyApp());
Color btnColor = Color(0xff03a9f3);
Color bgColor = Color(0xffe9f4fc);
String lasturl;
share() {
  Share.share('Check out this product - $lasturl');
}

Future<Position> _determinePosition() async {
  bool serviceEnabled;
  LocationPermission permission;

  // Test if location services are enabled.
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // Location services are not enabled don't continue
    // accessing the position and request users of the
    // App to enable the location services.
    return Future.error('Location services are disabled.');
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    if (permission == LocationPermission.denied) {
      // Permissions are denied, next time you could try
      // requesting permissions again (this is also where
      // Android's shouldShowRequestPermissionRationale
      // returned true. According to Android guidelines
      // your App should show an explanatory UI now.
      return Future.error('Location permissions are denied');
    }
  }

  // When we reach here, permissions are granted and we can
  // continue accessing the position of the device.
  return await Geolocator.getCurrentPosition();
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Qavenue',
      home: OfflineBuilder(
        connectivityBuilder: (
          BuildContext context,
          ConnectivityResult connectivity,
          Widget child,
        ) {
          print("$lasturl");
          final bool connected = connectivity != ConnectivityResult.none;
          return Container(
            child: connected
                ? MyHomePage()
                : Center(
                    child: Image.asset(
                      'assets/icon/images/offline_blue.gif',
                      fit: BoxFit.cover,
                      width: 200.0,
                    ),
                  ),
            color: bgColor,
          );
        },
        child: WebviewScaffold(
          url: lasturl,
          withJavascript: true,
          withZoom: false,
          hidden: true,
          geolocationEnabled: true,
          withLocalStorage: true,
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String url;
  final flutterWebviewPlugin = new FlutterWebviewPlugin();

  StreamSubscription<WebViewStateChanged>
      _onchanged; // here we checked the url state if it loaded or start Load or abort Load
  StreamSubscription<String> _onUrlChanged;

  @override
  void initState() {
    super.initState();
    _determinePosition();
    if (lasturl == "" || lasturl == url) {
      url = "https://qavenue.in";
    } else {
      url = lasturl;
    }
    _onchanged =
        flutterWebviewPlugin.onStateChanged.listen((WebViewStateChanged state) {
      if (mounted) {
        if (state.type == WebViewState.finishLoad) {
          // if the full website page loaded`
          print("loaded");
        } else if (state.type == WebViewState.abortLoad) {
          // if there is a problem with loading the url
          print("there is a problem");
        } else if (state.type == WebViewState.startLoad) {
          // if the url started loading
          print("start loading");
        }
      }
    });
    _onUrlChanged =
        flutterWebviewPlugin.onUrlChanged.listen((String url) async {
      lasturl = url;
      print("navigating to...$url");
      print("navigating lat to...$lasturl");
      if (url.contains("#share")) {
        print("navigating yes...$url");
        share();
        return;
      }
      if (url.startsWith("mailto") ||
          url.startsWith("tel") ||
          url.startsWith("sms")) {
        await flutterWebviewPlugin.stopLoading();
        await flutterWebviewPlugin.goBack();
        if (await canLaunch(url)) {
          await launch(url);
          return;
        }

        if (url.startsWith("mailto") ||
            url.startsWith("tel") ||
            url.startsWith("sms")) {
          WebviewScaffold(
            url: lasturl,
            withJavascript: true,
            withZoom: false,
            hidden: true,
            geolocationEnabled: true,
            withLocalStorage: true,
          );
        }
        print("couldn't launch $url");
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    flutterWebviewPlugin
        .dispose(); // disposing the webview widget to avoid any leaks
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: WillPopScope(
          onWillPop: () {
            flutterWebviewPlugin.canGoBack().then((value) {
              if (value) {
                flutterWebviewPlugin.goBack();
              } else {
                exit(0);
              }
            });
          },
          child: WebviewScaffold(
            url: url,
            withJavascript: true,
            withZoom: false,
            hidden: true,
            geolocationEnabled: true,
            withLocalStorage: true,
            initialChild: Container(
              color: Colors.white,
              child: Center(
                child: Image.asset('assets/icon/images/logo1.png'),
              ),
            ),
          )),
    );
  }
}
