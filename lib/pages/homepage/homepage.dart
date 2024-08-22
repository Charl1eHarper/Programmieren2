import 'package:flutter/material.dart';
import 'package:hoophub/pages/homepage/map_widget.dart';
import 'package:hoophub/pages/homepage/search_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isSearchVisible = false;

  void _onSearchIconPressed() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // Stelle sicher, dass der Body hinter der AppBar sein kann
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80), // Höhe der AppBar
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 20, left:16, right: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.transparent, // Hintergrundfarbe der AppBar auf transparent gesetzt
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white, // Tatsächliche Hintergrundfarbe der AppBar
                  borderRadius: BorderRadius.circular(30), // Abgerundete Ecken
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20.0), // Padding für Icons
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Center(
                      child: IconButton(
                        icon: const Icon(Icons.search, color: Colors.black, size: 35),
                        onPressed: _onSearchIconPressed,
                      ),
                    ),
                    Center(
                      child: IconButton(
                        icon: const Icon(Icons.people, color: Colors.black, size: 35),
                        onPressed: () {
                          Navigator.pushNamed(context, '/community');
                        },
                      ),
                    ),
                    Center(
                      child: IconButton(
                        icon: const Icon(Icons.account_circle, color: Colors.black, size: 35),
                        onPressed: () {
                          // Action for account button
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          MapWidget(),
          if (_isSearchVisible)
            Positioned(
              top: 110, // Abstand zwischen AppBar und Suchleiste
              left: 16,
              right: 16,
              child: SearchWidget(
                isSearchVisible: _isSearchVisible,
                onSearchIconPressed: _onSearchIconPressed,
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFFFFFFFF),
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.add, size: 40, color: Colors.black),
                onPressed: () {
                  // Action when add icon is pressed
                },
              ),
              IconButton(
                icon: const Icon(Icons.gps_fixed, size: 40, color: Colors.black),
                onPressed: () {
                  // Action when GPS icon is pressed
                },
              ),
              IconButton(
                icon: const Icon(Icons.settings, size: 40, color: Colors.black),
                onPressed: () {
                  // Action when settings icon is pressed
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
