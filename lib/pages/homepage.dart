import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Rename MyApp to HomePage to avoid naming conflicts
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

// State class for HomePageApp
class _HomePageState extends State<HomePage> {
  late GoogleMapController mapController; // Controller for Google Map
  final LatLng _center = const LatLng(45.521563, -122.677433); // Center point of the map

  // Method called when the map is created
  void _onMapCreated(GoogleMapController controller) {
    mapController = controller; // Save the map controller
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // Allows body to extend behind the AppBar
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Makes the AppBar transparent
        elevation: 0, // Removes shadow from the AppBar
        titleSpacing: 0, // Sets spacing for the title
        toolbarHeight: 80, // Sets height of the AppBar
        title: Align(
          alignment: Alignment.center, // Centers the child widget within the AppBar
          child: Container(
            width: 350, // Width of the container
            height: 55, // Height of the container
            padding: const EdgeInsets.symmetric(horizontal: 16.0), // Horizontal padding inside the container
            decoration: BoxDecoration(
              color: const Color(0xCC717171), // Background color with opacity
              borderRadius: BorderRadius.circular(35), // Rounded corners
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, // Spacing between the children
              children: [
                IconButton(
                  icon: const Icon(
                      Icons.search, color: Colors.black, size: 40), // Search icon button
                  onPressed: () {
                    // Define the action for the search button here
                  },
                ),
                IconButton(
                  icon: const Icon(
                      Icons.people, color: Colors.black, size: 40), // People icon button
                  onPressed: () {
                    // Define the action for the people button here
                  },
                ),
                IconButton(
                  icon: const Icon(
                      Icons.account_circle, color: Colors.black, size: 40), // Account icon button
                  onPressed: () {
                    // Define the action for the account button here
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: GoogleMap(
        onMapCreated: _onMapCreated, // Callback when the map is created
        initialCameraPosition: CameraPosition(
          target: _center, // Initial center point of the map
          zoom: 11.0, // Initial zoom level of the map
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF717171), // Background color of the BottomAppBar
        child: Container(
          height: 70, // Set the height of the bottom bar
          padding: const EdgeInsets.symmetric(horizontal: 16.0), // Add padding on the left and right
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space the icons evenly
            children: [
              IconButton(
                icon: const Icon(Icons.add, size: 40, color: Colors.black), // Home icon
                onPressed: () {
                  // Action when home icon is pressed
                },
              ),
              IconButton(
                icon: const Icon(Icons.gps_fixed, size: 40, color: Colors.black), // Map icon
                onPressed: () {
                  // Action when map icon is pressed
                },
              ),
              IconButton(
                icon: const Icon(Icons.settings, size: 40, color: Colors.black), // Settings icon
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
