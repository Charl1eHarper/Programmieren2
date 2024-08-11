import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late GoogleMapController mapController;

  final LatLng _center = const LatLng(45.521563, -122.677433);

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green[700],
      ),
      home: Scaffold(
        extendBodyBehindAppBar: true, // Ensures the AppBar floats over the map
        appBar: AppBar(
          backgroundColor: Colors.transparent, // Makes the AppBar transparent
          elevation: 0, // Removes shadow under the AppBar
          titleSpacing: 0,
          toolbarHeight: 125, // Set a height that fits your content
          title: Center(
            child: Container(
              width: 350,
              height: 55,
              margin: const EdgeInsets.only(top: 0), // Adjust this value to move the container down
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                color: const Color(0xCC717171),
                // Sets the container to the specified grey with 80% opacity
                borderRadius: BorderRadius.circular(35),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(
                        Icons.search, color: Colors.black, size: 35),
                    // Adjust size here
                    onPressed: () {
                      // Add function here
                    },
                  ),
                  IconButton(
                    icon: const Icon(
                        Icons.people, color: Colors.black, size: 35),
                    onPressed: () {
                      // Add function here
                    },
                  ),
                  IconButton(
                    icon: const Icon(
                        Icons.account_circle, color: Colors.black, size: 35),
                    // Adjust size here
                    onPressed: () {
                      // Add function here
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        body: GoogleMap(
          onMapCreated: _onMapCreated,
          initialCameraPosition: CameraPosition(
            target: _center,
            zoom: 11.0,
          ),
        ),
      ),
    );
  }
}