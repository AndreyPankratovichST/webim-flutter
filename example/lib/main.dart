import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:webim/webim.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  String _platformVersion = 'Unknown';

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await Webim.platformVersion;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(title: const Text('Plugin example app')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Running on: $_platformVersion\n'),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _buildSession,
                child: Text('Build session'),
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _resumeSession,
                child: Text('Resume session'),
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _pauseSession,
                child: Text('Pause session'),
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _sendMessage,
                child: Text('Send message'),
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () => _getLastMessages(10),
                child: Text('Get last messages'),
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _setMessageListener,
                child: Text('Set onMessage listener'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // String DEFAULT_ACCOUNT_NAME = "demo";
  //       String DEFAULT_LOCATION = "mobile";

  void _buildSession() async {
    final session =
        await Webim.buildSession(
          // accountName: "https://testchat.smpbank.ru",
          // locationName: 'mobile',
          accountName: "demo",
          locationName: 'mobile',
          // visitorFields:
          //     "{\"fields\":{\"id\":\"102480\",\"display_name\":\"Артамонов Александр Викторович\",\"email\":\"artosmp2@yandex.ru\"},\"hash\":\"1a0bc6835639fae8b88c3cd92757fd5317b2630c56cb81a1dff67c5e13acebd8\"}"
        ).catchError(
          (e) => _showShackBar(
            _scaffoldKey.currentContext ?? context,
            SnackBar(content: Text(e.toString())),
          ),
        );
    print(session);
  }

  void _resumeSession() async {
    await Webim.resumeSession();
  }

  void _pauseSession() async {
    await Webim.pauseSession();
  }

  void _sendMessage() async {
    final result = await Webim.sendMessage(message: 'AndX2 Test test message')
        .catchError((e) {
          _showShackBar(
            _scaffoldKey.currentContext ?? context,
            SnackBar(content: Text(e.toString())),
          );
        });
    print(result);
    if (result != null)
      _showShackBar(
        _scaffoldKey.currentContext ?? context,
        SnackBar(content: Text(result)),
      );
  }

  void _getLastMessages(int limit) async {
    final result = await Webim.getLastMessages(limit: limit).catchError((e) {
      _showShackBar(
        _scaffoldKey.currentContext ?? context,
        SnackBar(content: Text(e.toString())),
      );
    });
    print(result);
    if (result != null)
      _showShackBar(
        _scaffoldKey.currentContext ?? context,
        SnackBar(content: Text(result.toString())),
      );
  }

  void _setMessageListener() async {
    Webim.messageEventController.stream.listen(
      _onMessage,
      onError: _onMessageError,
    );
  }

  void _onMessage(MessageEvent event) {
    print(event);
  }

  void _onMessageError(dynamic event) {
    print(event);
  }

  void _showShackBar(BuildContext context, SnackBar snackBar) =>
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(snackBar);
}
