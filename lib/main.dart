import 'package:flutter/material.dart';
import 'smart_plug_scanner.dart'; 
import 'smart_tv_scanner.dart'; 

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Plug Scanner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.teal),
      home: SmartPlugScanner(), // Use this
      //home: SmartTVScanner(), // for testing purposes only
    );
  }
}
