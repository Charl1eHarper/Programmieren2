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
  late GoogleMapController _mapController; // Initialize the controller

  void _onSearchIconPressed() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller; // Set the controller when the map is created
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 20, left: 16.0, right: 16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.transparent,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
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
          MapWidget(onMapCreated: _onMapCreated), // Pass the map creation callback
          if (_isSearchVisible)
            Positioned(
              top: 95,
              left: 16,
              right: 16,
              child: SearchWidget(
                isSearchVisible: _isSearchVisible,
                onSearchIconPressed: _onSearchIconPressed,
                mapController: _mapController, // Pass the map controller to the SearchWidget
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
