import 'package:flutter/material.dart';
import '../ui/canvas_screen.dart';
import '../ui/notion_demo.dart';

class InfiniteCanvasApp extends StatelessWidget {
  const InfiniteCanvasApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Advanced Infinite Canvas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const CanvasScreen(),
      routes: {
        '/notion-demo': (context) => const NotionDemo(),
      },
    );
  }
}