import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

extension PseudoEasyLocalization on String {
  String tr(BuildContext context) => this;
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    final s = 'Plugin example app';
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text(s.tr(context)),
        ),
        body: const Center(
          child: Text('Running'),
        ),
      ),
    );
  }
}
