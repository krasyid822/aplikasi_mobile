import 'package:flutter/material.dart';
import 'video_gallery.dart';

void main() {
  runApp(VideoGalleryApp());
}

class VideoGalleryApp extends StatelessWidget {
  const VideoGalleryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Galeri Video Flutter',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: VideoGalleryPage(),
    );
  }
}
