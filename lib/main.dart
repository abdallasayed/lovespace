import 'package:flutter/material.dart';

void main() {
  runApp(const LoveSpaceApp());
}

class LoveSpaceApp extends StatelessWidget {
  const LoveSpaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LoveSpace',
      theme: ThemeData(
        primarySwatch: Colors.pink,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('LoveSpace ❤️'),
          backgroundColor: Colors.pink,
        ),
        body: const Center(
          child: Text(
            'بداية رحلتنا معاً',
            style: TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }
}

