import 'package:flutter/material.dart';
import 'pages/google_page.dart';
import 'pages/flutter_page.dart';
import 'pages/github_page.dart';

void main() {
  runApp(WebViewApp());
  }
  
  class WebViewApp extends StatefulWidget {
    @override
    _WebViewAppState createState() => _WebViewAppState();
    }
    
  class _WebViewAppState extends State<WebViewApp> {
    int _selectedIndex = 0;
  
    final List<Widget> _pages = [
      GooglePage(),
      FlutterPage(),
      GithubPage(),
      
    ];
    
    void _onItemTapped(int index) {
      setState(() {
        _selectedIndex = index;
      });
    }
    
    @override
    Widget build(BuildContext context) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Multi WebView Flutter',
        home: Scaffold(
          appBar: AppBar(
            title: Text('Multi WebView'),
            centerTitle: true,
            backgroundColor: Colors.blueGrey,
          ),
          body: _pages[_selectedIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            selectedItemColor: Colors.blue,
            unselectedItemColor: Colors.grey,
            onTap: _onItemTapped,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.search),
                label: 'Google',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.code),
                label: 'Flutter',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.cloud),
                label: 'GitHub',
              ),
            ],
          ),
        ),
      );
    }
  }


        