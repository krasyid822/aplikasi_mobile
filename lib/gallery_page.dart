import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  // Instance untuk memutar audio
  final AudioPlayer audioPlayer = AudioPlayer();

  // Daftar gambar dengan URL
  final List<String> images = const [
    'assets/image/tiger.png', // Tiger 0
    'assets/image/cat.png', // Cat 1
    'assets/image/squirrel.png', // Squirrel 2
    'assets/image/giraffe.png', // Giraffe 3
    'assets/image/panda.png', // Panda 4
    'assets/image/komodo.png', // Komodo 5
    'assets/image/caterpillar.png', // caterpillar 6
    'assets/image/hedgehog.png', // hedgehog 7
    'assets/image/jellyfish.png', // jellyfish 8
    'assets/image/piranha.png', // piranha 9
    // Tambahkan URL gambar lainnya sesuai kebutuhan
  ];

  // Daftar nama hewan yang sesuai dengan gambar
  final List<String> animalNames = const [
    'Tiger', // Tiger 0
    'Cat', // Cat 1
    'Squirrel', // Squirrel 2
    'Giraffe', // Giraffe 3
    'Panda', // Panda 4
    'Komodo', // Komodo 5
    'Caterpillar', // caterpillar 6
    'Hedgehog', // hedgehog 7
    'Jellyfish', // jellyfish 8
    'Piranha', // piranha 9
  ];

  // Mapping file audio untuk setiap gambar
  final List<String> audioFiles = const [
    'audio/tiger.mp3.o', // Audio untuk gambar tiger (index 0)
    'audio/cat.mp3.o', // Audio untuk gambar cat (index 1)
    'audio/squirrel.mp3.o', // Audio untuk gambar squirrel (index 2)
    'audio/giraffe.mp3.o', // Audio untuk gambar giraffe (index 3) - menggunakan tiger sebagai placeholder
    'audio/panda.mp3.o', // Audio untuk gambar panda (index 4) - menggunakan cat sebagai placeholder
    'audio/komodo.mp3.o', // Audio untuk gambar komodo (index 5) - menggunakan tiger sebagai placeholder
    'audio/caterpillar.mp3.o', // Audio untuk gambar ulat (index 6) - menggunakan squirrel sebagai placeholder
    'audio/hedgehog.mp3.o', // Audio untuk gambar landak (index 7) - menggunakan cat sebagai placeholder
    'audio/jellyfish.mp3.o', // Audio untuk gambar ubur-ubur (index 8) - menggunakan squirrel sebagai placeholder
    'audio/piranha.mp3.o', // Audio untuk gambar piranha (index 9) - menggunakan tiger sebagai placeholder
  ];

  @override
  void dispose() {
    // Bersihkan resource audio player saat widget dihapus
    audioPlayer.dispose();
    super.dispose();
  }

  /// Fungsi untuk memutar audio berdasarkan index gambar
  ///
  /// [index] - index gambar yang diklik dalam grid
  ///
  /// Fungsi ini akan:
  /// 1. Menghentikan audio yang sedang diputar (jika ada)
  /// 2. Memutar file audio yang sesuai dengan gambar dalam mode loop
  /// 3. Menangani error jika file audio tidak dapat diputar
  Future<void> playAudio(int index) async {
    try {
      // Hentikan audio yang sedang diputar
      await audioPlayer.stop();

      // Putar audio berdasarkan index gambar dengan mode loop
      if (index < audioFiles.length) {
        await audioPlayer.play(AssetSource(audioFiles[index]));
        // Set audio untuk loop
        await audioPlayer.setReleaseMode(ReleaseMode.loop);
      }
    } catch (e) {
      // Tangani error jika terjadi masalah saat memutar audio
      debugPrint('Error playing audio: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gallery Foto'), centerTitle: true),
      body: GridView.builder(
        padding: const EdgeInsets.all(10),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // Jumlah kolom
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: images.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => playAudio(index), // Putar audio saat gambar disentuh
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withAlpha((0.3 * 255).round()),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                      child: Image.asset(images[index], fit: BoxFit.cover),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                    ),
                    child: Text(
                      animalNames[index],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
