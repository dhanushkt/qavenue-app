import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:flutter_offline/flutter_offline.dart';

void main() => runApp(MyApp());
Color btnColor = Color(0xff03a9f3);
Color bgColor = Color(0xffe9f4fc);

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
          final bool connected = connectivity != ConnectivityResult.none;
          return Container(
            child: connected
                ? MyHomePage()
                : Center(
                    child: Image.asset(
                      'assets/offline_blue.gif',
                      fit: BoxFit.cover,
                      width: 200.0,
                    ),
                  ),
            color: bgColor,
          );
        },
        child: MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String url = "https://qavenue.in/";

  final flutterWebviewPlugin = new FlutterWebviewPlugin();
  StreamSubscription<WebViewStateChanged>
      _onchanged; // here we checked the url state if it loaded or start Load or abort Load

  @override
  void initState() {
    super.initState();
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
            initialChild: Container(
              color: Colors.white,
              child: Center(
                child: Text(
                  'LOADING',
                  style: TextStyle(
                    color: btnColor,
                  ),
                ),
              ),
            )),
      ),
    );
  }
}
