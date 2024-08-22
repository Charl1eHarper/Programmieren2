import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hoophub/pages/homepage/map_widget.dart';
import 'package:hoophub/pages/homepage/search_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isSearchVisible = false;
  late GoogleMapController _mapController;

  void _onSearchIconPressed() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final appBarHeight = screenHeight * 0.115; // Höhe der AppBar
    final searchBarTopPosition = appBarHeight + screenHeight * 0.025; // Position der Suchleiste direkt unter der AppBar

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(appBarHeight),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenHeight * 0.015),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.transparent,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(screenHeight * 0.04),
                ),
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Center(
                      child: IconButton(
                        icon: const Icon(Icons.search, color: Colors.black),
                        iconSize: screenWidth * 0.1,
                        onPressed: _onSearchIconPressed,
                      ),
                    ),
                    Center(
                      child: IconButton(
                        icon: const Icon(Icons.people, color: Colors.black),
                        iconSize: screenWidth * 0.1,
                        onPressed: () {
                          Navigator.pushNamed(context, '/community');
                        },
                      ),
                    ),
                    Center(
                      child: IconButton(
                        icon: const Icon(Icons.account_circle, color: Colors.black),
                        iconSize: screenWidth * 0.1,
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
          MapWidget(onMapCreated: _onMapCreated),
          if (_isSearchVisible)
            Positioned(
              top: searchBarTopPosition,
              left: screenWidth * 0.04,
              right: screenWidth * 0.04,
              child: SearchWidget(
                isSearchVisible: _isSearchVisible,
                onSearchIconPressed: _onSearchIconPressed,
                mapController: _mapController,
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        height: screenHeight * 0.09, // Höhe der unteren Leiste
        color: Colors.white, // Hintergrundfarbe der Leiste
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.add, color: Colors.black),
                iconSize: screenWidth * 0.1, // Größe des Icons
                onPressed: () {
                  // Aktion beim Drücken des Plus-Icons
                },
              ),
              IconButton(
                icon: const Icon(Icons.gps_fixed, color: Colors.black),
                iconSize: screenWidth * 0.1,
                onPressed: () {
                  // Aktion beim Drücken des GPS-Icons
                },
              ),
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.black),
                iconSize: screenWidth * 0.1,
                onPressed: () {
                  // Aktion beim Drücken des Einstellungs-Icons
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
