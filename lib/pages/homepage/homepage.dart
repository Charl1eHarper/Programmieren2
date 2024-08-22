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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        toolbarHeight: _isSearchVisible ? 120 : 80,
        title: SearchWidget(
          isSearchVisible: _isSearchVisible,
          onSearchIconPressed: _onSearchIconPressed,
        ),
      ),
      body: Stack(
        children: [
          MapWidget(),
          // Weitere Widgets hier
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
                icon: const Icon(Icons.settings,
                    size: 40, color: Colors.black),
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
