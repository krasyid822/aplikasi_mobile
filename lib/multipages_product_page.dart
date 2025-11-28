import 'package:flutter/material.dart';

class MultipagesProductPage extends StatelessWidget {
  const MultipagesProductPage({super.key});

  final List<String> images = const [
    'https://images.pexels.com/photos/33985102/pexels-photo-33985102.jpeg',
    'https://images.pexels.com/photos/821653/pexels-photo-821653.jpeg',
    'https://images.pexels.com/photos/27548789/pexels-photo-27548789.jpeg',
    // Tambahkan URL gambar lainnya sesuai kebutuhan
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gallery Produk'), centerTitle: true),
      body: GridView.builder(
        padding: const EdgeInsets.all(10),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // Jumlah kolom
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: images.length,
        itemBuilder: (context, index) {
          return Image.network(images[index], fit: BoxFit.cover);
        },
      ),
    );
  }
}
