import 'package:flutter/material.dart';
import 'screens/library_screen.dart';

void main() {
  runApp(const MediaCentreApp());
}

class MediaCentreApp extends StatelessWidget {
  const MediaCentreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MediaCentre',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const LibraryScreen(),
    );
  }
}
