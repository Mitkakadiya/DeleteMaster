import 'package:flutter/material.dart';
import 'image_gallery_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Delete Master',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: ImageGalleryPage(),
    );
  }
}
