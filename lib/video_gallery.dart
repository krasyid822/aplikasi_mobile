import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

// Conditional imports for web platform only
import 'video_gallery_web_stub.dart'
    if (dart.library.html) 'video_gallery_web.dart';

// Enum untuk mode sumber video
enum VideoSourceMode {
  both, // Tampilkan static + dynamic
  staticOnly, // Tampilkan hanya static
  dynamicOnly, // Tampilkan hanya dynamic
}

class VideoGalleryPage extends StatefulWidget {
  const VideoGalleryPage({super.key});

  @override
  _VideoGalleryPageState createState() => _VideoGalleryPageState();
}

class _VideoGalleryPageState extends State<VideoGalleryPage> {
  bool isDarkMode = false;
  String searchQuery = '';
  List<String> favoriteVideos = [];
  TextEditingController searchController = TextEditingController();
  bool isLoading = false;
  bool showFavoritesOnly = false;
  VideoSourceMode videoSourceMode =
      VideoSourceMode.both; // Default: tampilkan keduanya

  // Scroll controller dan state untuk hide/show appbar dan search
  ScrollController scrollController = ScrollController();
  bool isScrollingDown = false;
  double lastScrollPosition = 0.0;

  // Simpan orientasi saat ini
  List<DeviceOrientation> currentOrientations = [];

  // Check if platform is Android (untuk disable hide/show appbar di Android)
  bool get isAndroid {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android;
  }

  // YouTube API Key (Demo - in production, use environment variables)
  static const String _youtubeApiKey =
      'AIzaSyDGaajmqvVvwyHxtKOou6sVxpuV9__zzno';
  // Kata kunci pencarian untuk video Flutter
  static const String _searchQuery = 'flutter tutorial';
  // Static video list (fallback jika API gagal)
  final List<Map<String, String>> staticVideoList = [
    {
      "title": "Belajar Flutter Dasar",
      "url": "https://www.youtube.com/watch?v=VPvVD8t02U8",
      "description": "Tutorial lengkap Flutter untuk pemula",
    },
    {
      "title": "Membangun Aplikasi Flutter CRUD",
      "url": "https://www.youtube.com/watch?v=1gDhl4leEzA",
      "description": "Belajar membuat aplikasi CRUD dengan Flutter",
    },
    {
      "title": "Flutter UI Tutorial",
      "url": "https://www.youtube.com/watch?v=ExKYjqgswJg",
      "description": "Desain UI yang menarik dengan Flutter",
    },
    {
      "title": "Dart Programming for Beginners",
      "url": "https://www.youtube.com/watch?v=Ej_Pcr4uC2Q",
      "description": "Belajar dasar-dasar pemrograman Dart",
    },
    {
      "title": "Flutter State Management",
      "url": "https://www.youtube.com/watch?v=d_m5csmrf7I",
      "description": "Mengelola state dalam aplikasi Flutter",
    },
    {
      "title": "Firebase dengan Flutter",
      "url": "https://www.youtube.com/watch?v=sfA3NWDBPZ4",
      "description": "Integrasi Firebase dalam aplikasi Flutter",
    },
  ];

  // Dynamic video list dari YouTube API
  List<Map<String, String>> dynamicVideoList = [];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _loadYouTubeVideos();

    // Setup scroll listener untuk hide/show appbar dan search
    scrollController.addListener(_onScroll);
  }

  // Fungsi untuk mendeteksi arah scroll
  void _onScroll() {
    // Disable hide/show appbar untuk Android
    if (isAndroid) return;

    final currentScrollPosition = scrollController.position.pixels;

    // Jika scroll lebih dari 50 pixel
    if (scrollController.position.pixels > 50) {
      if (currentScrollPosition > lastScrollPosition && !isScrollingDown) {
        // Scrolling down
        setState(() {
          isScrollingDown = true;
        });
      } else if (currentScrollPosition < lastScrollPosition &&
          isScrollingDown) {
        // Scrolling up
        setState(() {
          isScrollingDown = false;
        });
      }
    } else {
      // Di posisi atas, selalu tampilkan
      if (isScrollingDown) {
        setState(() {
          isScrollingDown = false;
        });
      }
    }

    lastScrollPosition = currentScrollPosition;
  }

  // Get current video list berdasarkan mode yang dipilih
  List<Map<String, String>> get currentVideoList {
    switch (videoSourceMode) {
      case VideoSourceMode.staticOnly:
        return staticVideoList;
      case VideoSourceMode.dynamicOnly:
        return dynamicVideoList;
      case VideoSourceMode.both:
        // Gabungkan static dan dynamic, hindari duplikat berdasarkan URL
        final combinedList = <Map<String, String>>[...staticVideoList];
        for (var dynamicVideo in dynamicVideoList) {
          // Cek apakah video sudah ada di list (berdasarkan URL)
          if (!combinedList.any((v) => v['url'] == dynamicVideo['url'])) {
            combinedList.add(dynamicVideo);
          }
        }
        return combinedList;
    }
  }

  // Load YouTube videos via API
  Future<void> _loadYouTubeVideos() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Demo implementation - dalam production gunakan API key yang valid
      final url =
          'https://www.googleapis.com/youtube/v3/search'
          '?key=$_youtubeApiKey'
          '&q=$_searchQuery'
          '&part=snippet,id'
          '&order=relevance'
          '&maxResults=10'
          '&type=video';

      debugPrint('Fetching YouTube videos from: $url');
      final response = await http.get(Uri.parse(url));

      debugPrint('Response status code: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> items = data['items'] ?? [];

        debugPrint('Number of videos fetched: ${items.length}');

        // Jika video kurang dari 3, gunakan static list sebagai fallback
        if (items.length < 3) {
          debugPrint(
            'Too few videos from API (${items.length}), using static list instead',
          );
          // Jangan set dynamicVideoList, biarkan kosong sehingga currentVideoList return staticVideoList
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Menggunakan video offline. API quota terbatas.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else {
          setState(() {
            dynamicVideoList = items.map<Map<String, String>>((item) {
              return {
                'title': item['snippet']['title'],
                'description': item['snippet']['description'],
                'url':
                    'https://www.youtube.com/watch?v=${item['id']['videoId']}',
              };
            }).toList();
          });

          debugPrint(
            'Dynamic video list updated with ${dynamicVideoList.length} videos',
          );
        }
      } else {
        debugPrint('API Error: ${response.statusCode} - ${response.body}');
        // Gunakan static list jika API gagal
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Menggunakan video offline. API error: ${response.statusCode}',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      // Jika API gagal, gunakan static list
      debugPrint('YouTube API Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Menggunakan video offline. Periksa koneksi internet.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }

    setState(() {
      isLoading = false;
    });

    debugPrint('Current video list count: ${currentVideoList.length}');
  }

  @override
  void dispose() {
    searchController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  // Load preferences untuk dark mode dan favorites
  Future<void> _loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = prefs.getBool('isDarkMode') ?? false;
      favoriteVideos = prefs.getStringList('favoriteVideos') ?? [];
    });
  }

  // Save preferences
  Future<void> _savePreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDarkMode);
    await prefs.setStringList('favoriteVideos', favoriteVideos);
  }

  // Toggle dark mode
  void _toggleDarkMode() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
    _savePreferences();
  }

  // Toggle favorite video
  void _toggleFavorite(String videoUrl) {
    setState(() {
      if (favoriteVideos.contains(videoUrl)) {
        favoriteVideos.remove(videoUrl);
      } else {
        favoriteVideos.add(videoUrl);
      }
    });
    _savePreferences();
  }

  // Filter videos berdasarkan search query dan favorites
  List<Map<String, String>> get filteredVideos {
    List<Map<String, String>> baseList = currentVideoList;

    // Filter berdasarkan favorites jika showFavoritesOnly aktif
    if (showFavoritesOnly) {
      baseList = baseList.where((video) {
        return favoriteVideos.contains(video['url']);
      }).toList();
    }

    // Filter berdasarkan search query
    if (searchQuery.isEmpty) {
      return baseList;
    }
    return baseList.where((video) {
      return video['title']!.toLowerCase().contains(
            searchQuery.toLowerCase(),
          ) ||
          video['description']!.toLowerCase().contains(
            searchQuery.toLowerCase(),
          );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('=== BUILD ===');
    debugPrint('Video Source Mode: $videoSourceMode');
    debugPrint('Static video list: ${staticVideoList.length}');
    debugPrint('Dynamic video list: ${dynamicVideoList.length}');
    debugPrint('Current video list: ${currentVideoList.length}');
    debugPrint('Filtered videos: ${filteredVideos.length}');
    debugPrint('Search query: "$searchQuery"');
    debugPrint('Show favorites only: $showFavoritesOnly');

    return Theme(
      data: isDarkMode ? ThemeData.dark() : ThemeData.light(),
      child: Scaffold(
        extendBodyBehindAppBar: false,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(
            (isScrollingDown && !isAndroid) ? 0.0 : (kToolbarHeight + 80.0),
          ),
          child: ClipRect(
            child: AnimatedContainer(
              duration: Duration(milliseconds: 200),
              height: (isScrollingDown && !isAndroid) ? 0.0 : null,
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // AppBar
                    Container(
                      height: kToolbarHeight,
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.black : Colors.white,
                      ),
                      child: Row(
                        children: [
                          // Title
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(left: 16.0),
                              child: Text(
                                'Galeri Video Flutter',
                                style: TextStyle(
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.black,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          // Refresh YouTube Videos
                          IconButton(
                            icon: Icon(Icons.refresh),
                            color: isDarkMode ? Colors.white : Colors.black,
                            onPressed: _loadYouTubeVideos,
                            tooltip: 'Refresh Videos',
                          ),
                          // Video Source Mode Toggle with Badge
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              PopupMenuButton<VideoSourceMode>(
                                icon: Icon(Icons.video_library),
                                color: isDarkMode ? Colors.black : Colors.white,
                                tooltip: 'Filter Sumber Video',
                                onSelected: (VideoSourceMode mode) {
                                  setState(() {
                                    videoSourceMode = mode;
                                  });
                                },
                                itemBuilder: (BuildContext context) =>
                                    <PopupMenuEntry<VideoSourceMode>>[
                                      // Header dengan status informasi
                                      PopupMenuItem<VideoSourceMode>(
                                        enabled: false,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Sumber Video',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: isDarkMode
                                                    ? Colors.white
                                                    : Colors.black,
                                              ),
                                            ),
                                            SizedBox(height: 8),
                                            // Status bar dalam popup
                                            Container(
                                              padding: EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: isDarkMode
                                                    ? Colors.black26
                                                    : Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.storage,
                                                        size: 16,
                                                        color: Colors.orange,
                                                      ),
                                                      SizedBox(width: 6),
                                                      Text(
                                                        'Static: ${staticVideoList.length} video',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: isDarkMode
                                                              ? Colors.white
                                                              : Colors.black,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.cloud_download,
                                                        size: 16,
                                                        color: Colors.green,
                                                      ),
                                                      SizedBox(width: 6),
                                                      Text(
                                                        'Dynamic: ${dynamicVideoList.length} video',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: isDarkMode
                                                              ? Colors.white
                                                              : Colors.black,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(height: 4),
                                                  Divider(height: 8),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.video_library,
                                                        size: 16,
                                                        color: Colors.blue,
                                                      ),
                                                      SizedBox(width: 6),
                                                      Text(
                                                        'Total: ${currentVideoList.length} video',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.blue,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            SizedBox(height: 8),
                                            Divider(height: 1),
                                          ],
                                        ),
                                      ),
                                      // Mode options
                                      PopupMenuItem<VideoSourceMode>(
                                        value: VideoSourceMode.both,
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.library_add_check,
                                              color:
                                                  videoSourceMode ==
                                                      VideoSourceMode.both
                                                  ? Colors.blue
                                                  : Colors.grey,
                                            ),
                                            SizedBox(width: 12),
                                            Expanded(
                                              child: Text('Semua Video'),
                                            ),
                                            if (videoSourceMode ==
                                                VideoSourceMode.both)
                                              Icon(
                                                Icons.check,
                                                color: Colors.blue,
                                                size: 20,
                                              ),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem<VideoSourceMode>(
                                        value: VideoSourceMode.staticOnly,
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.storage,
                                              color:
                                                  videoSourceMode ==
                                                      VideoSourceMode.staticOnly
                                                  ? Colors.orange
                                                  : Colors.grey,
                                            ),
                                            SizedBox(width: 12),
                                            Expanded(
                                              child: Text('Hanya Static'),
                                            ),
                                            if (videoSourceMode ==
                                                VideoSourceMode.staticOnly)
                                              Icon(
                                                Icons.check,
                                                color: Colors.orange,
                                                size: 20,
                                              ),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem<VideoSourceMode>(
                                        value: VideoSourceMode.dynamicOnly,
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.cloud_download,
                                              color:
                                                  videoSourceMode ==
                                                      VideoSourceMode
                                                          .dynamicOnly
                                                  ? Colors.green
                                                  : Colors.grey,
                                            ),
                                            SizedBox(width: 12),
                                            Expanded(
                                              child: Text('Hanya Dynamic'),
                                            ),
                                            if (videoSourceMode ==
                                                VideoSourceMode.dynamicOnly)
                                              Icon(
                                                Icons.check,
                                                color: Colors.green,
                                                size: 20,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                              ),
                              // Badge indicator untuk mode aktif
                              if (videoSourceMode != VideoSourceMode.both)
                                Positioned(
                                  right: 8,
                                  top: 8,
                                  child: Container(
                                    padding: EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color:
                                          videoSourceMode ==
                                              VideoSourceMode.staticOnly
                                          ? Colors.orange
                                          : Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      videoSourceMode ==
                                              VideoSourceMode.staticOnly
                                          ? Icons.storage
                                          : Icons.cloud_download,
                                      size: 10,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          // Toggle Favorites Filter
                          IconButton(
                            icon: Icon(
                              showFavoritesOnly
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: showFavoritesOnly
                                  ? Colors.red
                                  : isDarkMode
                                  ? Colors.white
                                  : Colors.black,
                            ),
                            onPressed: () {
                              setState(() {
                                showFavoritesOnly = !showFavoritesOnly;
                              });
                            },
                            tooltip: showFavoritesOnly
                                ? 'Show All Videos'
                                : 'Show Favorites Only',
                          ),
                          // Dark Mode Toggle
                          IconButton(
                            icon: Icon(
                              isDarkMode ? Icons.light_mode : Icons.dark_mode,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                            onPressed: _toggleDarkMode,
                            tooltip: 'Toggle Dark Mode',
                          ),
                        ],
                      ),
                    ),
                    // Search Bar terintegrasi di bawah AppBar
                    Container(
                      color: isDarkMode ? Colors.black : Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: 'Cari video...',
                          prefixIcon: Icon(Icons.search),
                          suffixIcon: searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear),
                                  onPressed: () {
                                    setState(() {
                                      searchController.clear();
                                      searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: isDarkMode
                              ? Colors.grey[800]
                              : Colors.white,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            // Loading Indicator
            if (isLoading)
              LinearProgressIndicator(
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
              ),
            // GridView untuk video (2 kolom)
            Expanded(
              child: filteredVideos.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.video_library_outlined,
                            size: 80,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            showFavoritesOnly
                                ? 'Tidak ada video favorit'
                                : searchQuery.isNotEmpty
                                ? 'Tidak ada video yang cocok dengan pencarian'
                                : videoSourceMode ==
                                          VideoSourceMode.dynamicOnly &&
                                      dynamicVideoList.isEmpty
                                ? 'Tidak ada video dynamic.\nGunakan mode "Semua" atau "Static".'
                                : 'Tidak ada video',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (showFavoritesOnly ||
                              searchQuery.isNotEmpty ||
                              (videoSourceMode == VideoSourceMode.dynamicOnly &&
                                  dynamicVideoList.isEmpty))
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    showFavoritesOnly = false;
                                    searchQuery = '';
                                    searchController.clear();
                                    if (videoSourceMode ==
                                            VideoSourceMode.dynamicOnly &&
                                        dynamicVideoList.isEmpty) {
                                      videoSourceMode = VideoSourceMode.both;
                                    }
                                  });
                                },
                                child: Text(
                                  videoSourceMode ==
                                              VideoSourceMode.dynamicOnly &&
                                          dynamicVideoList.isEmpty
                                      ? 'Tampilkan Semua Video'
                                      : 'Reset Filter',
                                ),
                              ),
                            ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      controller: scrollController,
                      padding: EdgeInsets.all(10),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, // 2 kolom sesuai task
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio:
                            MediaQuery.of(context).orientation ==
                                Orientation.landscape
                            ? 1.1 // Landscape mode
                            : 0.8, // Portrait mode - Untuk mengatur ketinggian card video agar tidak overflow
                      ),
                      itemCount: filteredVideos.length,
                      itemBuilder: (context, index) {
                        final video = filteredVideos[index];
                        final videoId = YoutubePlayer.convertUrlToId(
                          video['url']!,
                        );
                        final isFavorite = favoriteVideos.contains(
                          video['url'],
                        );

                        return Card(
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Thumbnail Video dengan Play Button
                              AspectRatio(
                                aspectRatio: 16 / 9,
                                child: Stack(
                                  children: [
                                    SizedBox(
                                      width: double.infinity,
                                      height: double.infinity,
                                      child: videoId != null
                                          ? Image.network(
                                              'https://img.youtube.com/vi/$videoId/maxresdefault.jpg',
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                    return Container(
                                                      color: Colors.grey[300],
                                                      child: Icon(
                                                        Icons.video_library,
                                                        size: 50,
                                                      ),
                                                    );
                                                  },
                                            )
                                          : Container(
                                              color: Colors.grey[300],
                                              child: Icon(
                                                Icons.video_library,
                                                size: 50,
                                              ),
                                            ),
                                    ),
                                    // Play Button di tengah thumbnail
                                    Positioned.fill(
                                      child: Container(
                                        color: Colors.black.withOpacity(0.3),
                                        child: Center(
                                          child: GestureDetector(
                                            onTap: () =>
                                                _playVideo(context, video),
                                            child: Container(
                                              padding: EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.red.withOpacity(
                                                  0.9,
                                                ),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.play_arrow,
                                                color: Colors.white,
                                                size: 32,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Video Info dengan overflow protection
                              Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Title dengan overflow protection
                                    Text(
                                      video['title']!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 3),
                                    // Description dengan overflow protection
                                    Text(
                                      video['description']!,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[600],
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 6),
                                    // Action Buttons (hanya Favorite dan Share)
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        // Favorite Button
                                        InkWell(
                                          onTap: () =>
                                              _toggleFavorite(video['url']!),
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                              vertical: 3,
                                              horizontal: 6,
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  isFavorite
                                                      ? Icons.favorite
                                                      : Icons.favorite_border,
                                                  color: isFavorite
                                                      ? Colors.red
                                                      : Colors.grey,
                                                  size: 16,
                                                ),
                                                SizedBox(width: 3),
                                                Text(
                                                  'Favorit',
                                                  style: TextStyle(fontSize: 9),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        // Share Button
                                        InkWell(
                                          onTap: () => _shareVideo(video),
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                              vertical: 3,
                                              horizontal: 6,
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.share,
                                                  color: Colors.blue,
                                                  size: 16,
                                                ),
                                                SizedBox(width: 3),
                                                Text(
                                                  'Share',
                                                  style: TextStyle(fontSize: 9),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Function untuk play video dengan dukungan fullscreen yang proper
  void _playVideo(BuildContext context, Map<String, String> video) {
    final videoId = YoutubePlayer.convertUrlToId(video['url']!);

    // Jika di web, gunakan iframe embed dialog
    if (kIsWeb) {
      _playVideoInWebDialog(context, video, videoId!);
      return;
    }

    // Untuk mobile (Android/iOS), gunakan youtube player dengan fullscreen support
    if (videoId != null) {
      // Simpan orientasi saat ini sebelum masuk fullscreen
      currentOrientations = [
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ];

      YoutubePlayerController controller = YoutubePlayerController(
        initialVideoId: videoId,
        flags: YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
          loop: false,
          enableCaption: true,
          captionLanguage: 'id', // Bahasa Indonesia
          hideControls: false,
          controlsVisibleAtStart: true,
          forceHD: false,
        ),
      );

      // Navigate ke halaman player dengan fullscreen support
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => _VideoPlayerPage(
            controller: controller,
            video: video,
            onDispose: () {
              // Restore system UI setelah keluar
              SystemChrome.setEnabledSystemUIMode(
                SystemUiMode.edgeToEdge,
                overlays: SystemUiOverlay.values,
              );
              SystemChrome.setPreferredOrientations(currentOrientations);
              controller.dispose();
            },
          ),
        ),
      ).then((_) {
        // Restore system UI setelah keluar dari player
        SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.edgeToEdge,
          overlays: SystemUiOverlay.values,
        );
        SystemChrome.setPreferredOrientations(currentOrientations);
        controller.dispose();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: Tidak dapat memutar video'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Function untuk play video di web menggunakan iframe embed dialog
  void _playVideoInWebDialog(
    BuildContext context,
    Map<String, String> video,
    String videoId,
  ) {
    // Register iframe view factory untuk web
    final String viewType =
        'youtube-player-$videoId-${DateTime.now().millisecondsSinceEpoch}';

    if (kIsWeb) {
      registerWebView(viewType, videoId);
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header dengan tombol close
              Container(
                color: Colors.black87,
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        video['title']!,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Tutup',
                    ),
                  ],
                ),
              ),
              // YouTube Iframe Player
              Expanded(
                child: Container(
                  color: Colors.black,
                  child: HtmlElementView(viewType: viewType),
                ),
              ),
              // Video Info
              Container(
                color: Colors.black87,
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      video['description']!,
                      style: TextStyle(fontSize: 14, color: Colors.grey[300]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(Icons.close),
                          label: Text('Tutup'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            _shareVideo(video);
                          },
                          icon: Icon(Icons.share),
                          label: Text('Share'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Function untuk share video dengan copy to clipboard
  void _shareVideo(Map<String, String> video) {
    // Copy URL video ke clipboard
    Clipboard.setData(ClipboardData(text: video['url']!)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Link video "${video['title']}" telah disalin ke clipboard!',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    });
  }
}

// Widget terpisah untuk video player dengan fullscreen support
class _VideoPlayerPage extends StatefulWidget {
  final YoutubePlayerController controller;
  final Map<String, String> video;
  final VoidCallback onDispose;

  const _VideoPlayerPage({
    required this.controller,
    required this.video,
    required this.onDispose,
  });

  @override
  _VideoPlayerPageState createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<_VideoPlayerPage> {
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    // Listen untuk perubahan fullscreen dari YouTube player
    widget.controller.addListener(_onPlayerStateChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onPlayerStateChange);
    widget.onDispose();
    super.dispose();
  }

  void _onPlayerStateChange() {
    // Deteksi perubahan fullscreen
    if (widget.controller.value.isFullScreen != _isFullScreen) {
      setState(() {
        _isFullScreen = widget.controller.value.isFullScreen;
      });
      _handleFullScreenChange(_isFullScreen);
    }
  }

  void _handleFullScreenChange(bool isFullScreen) {
    if (isFullScreen) {
      // Masuk ke mode fullscreen
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersiveSticky,
        overlays: [],
      );
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      // Keluar dari mode fullscreen
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.edgeToEdge,
        overlays: SystemUiOverlay.values,
      );
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Jika dalam mode fullscreen, keluar dari fullscreen dulu
        if (_isFullScreen) {
          widget.controller.toggleFullScreenMode();
          return false;
        }
        // Restore system UI saat keluar
        SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.edgeToEdge,
          overlays: SystemUiOverlay.values,
        );
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _isFullScreen ? _buildFullScreenPlayer() : _buildNormalPlayer(),
      ),
    );
  }

  // Build player dalam mode fullscreen (hanya video)
  Widget _buildFullScreenPlayer() {
    return Center(
      child: YoutubePlayer(
        controller: widget.controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: Colors.red,
        progressColors: ProgressBarColors(
          playedColor: Colors.red,
          handleColor: Colors.redAccent,
          bufferedColor: Colors.grey,
          backgroundColor: Colors.black,
        ),
        aspectRatio: 16 / 9,
        onReady: () {
          debugPrint('Player is ready in fullscreen mode.');
        },
      ),
    );
  }

  // Build player dalam mode normal (dengan info video)
  Widget _buildNormalPlayer() {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Video Player
            YoutubePlayer(
              controller: widget.controller,
              showVideoProgressIndicator: true,
              progressIndicatorColor: Colors.red,
              progressColors: ProgressBarColors(
                playedColor: Colors.red,
                handleColor: Colors.redAccent,
                bufferedColor: Colors.grey,
                backgroundColor: Colors.black,
              ),
              aspectRatio: 16 / 9,
              onReady: () {
                debugPrint('Player is ready.');
              },
              onEnded: (data) {
                // Restore system UI dan kembali
                SystemChrome.setEnabledSystemUIMode(
                  SystemUiMode.edgeToEdge,
                  overlays: SystemUiOverlay.values,
                );
                SystemChrome.setPreferredOrientations([
                  DeviceOrientation.portraitUp,
                  DeviceOrientation.portraitDown,
                  DeviceOrientation.landscapeLeft,
                  DeviceOrientation.landscapeRight,
                ]);
                Navigator.of(context).pop();
              },
            ),
            // Video Info
            Container(
              color: Colors.black,
              padding: const EdgeInsets.all(16.0),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.video['title']!,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    widget.video['description']!,
                    style: TextStyle(fontSize: 14, color: Colors.grey[300]),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          // Restore system UI
                          SystemChrome.setEnabledSystemUIMode(
                            SystemUiMode.edgeToEdge,
                            overlays: SystemUiOverlay.values,
                          );
                          SystemChrome.setPreferredOrientations([
                            DeviceOrientation.portraitUp,
                            DeviceOrientation.portraitDown,
                            DeviceOrientation.landscapeLeft,
                            DeviceOrientation.landscapeRight,
                          ]);
                          Navigator.of(context).pop();
                        },
                        icon: Icon(Icons.close),
                        label: Text('Tutup'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          _shareVideo(widget.video);
                        },
                        icon: Icon(Icons.share),
                        label: Text('Share'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Function untuk share video dengan copy to clipboard
  void _shareVideo(Map<String, String> video) {
    Clipboard.setData(ClipboardData(text: video['url']!)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Link video "${video['title']}" telah disalin ke clipboard!',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    });
  }
}
