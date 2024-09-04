import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hoophub/pages/homepage/map_widget.dart';
import 'package:hoophub/pages/homepage/search_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isSearchVisible = false;  // Flag to control the visibility of the search bar
  bool _isInfoWindowVisible = false;  // Flag to control the visibility of the info window
  late String _infoWindowTitle;  // Holds the title of the info window
  late String _infoWindowImage;  // Holds the image URL of the info window
  Offset? _infoWindowPosition;  // Holds the position of the info window on the screen

  final Set<Marker> _markers = {};  // Holds the set of map markers
  late GoogleMapController _mapController;  // Controller for Google Map
  GoogleMapsPlaces places = GoogleMapsPlaces(apiKey: 'AIzaSyB-Auv39s_lM1kjpfOBySaQwxTMq5kfY-o');  // Places API instance

  final FocusNode _searchFocusNode = FocusNode();  // Focus node for the search bar
  StreamSubscription<Position>? _positionStream;  // Subscription to location stream updates

  BitmapDescriptor? _userLocationIcon;  // Custom icon for the user's location marker
  BitmapDescriptor? _basketballMarkerIcon;  // Custom icon for basketball court markers

  @override
  void initState() {
    super.initState();

    _searchFocusNode.addListener(() {  // Add listener to detect when the search field gains/loses focus
      if (_searchFocusNode.hasFocus) {
        setState(() {
          _isInfoWindowVisible = false;  // Hide the info window when search bar is focused
        });
      }
    });

    _loadCustomMarkers();  // Load custom markers for the map
    _getUserLocation(initial: true);  // Get the user's initial location
    _trackLocationChanges();  // Start tracking the user's location
  }

  @override
  void dispose() {
    _positionStream?.cancel();  // Cancel the location stream subscription
    _searchFocusNode.dispose();  // Dispose of the search focus node
    super.dispose();
  }

  Future<void> _loadCustomMarkers() async {  // Load custom marker icons from assets
    _userLocationIcon = await BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/user_location_icon.png',
    );

    _basketballMarkerIcon = await BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(30, 30)),
      'assets/basketball_marker.png',
    );
  }

  Future<void> _getUserLocation({bool initial = false}) async {  // Get the current location of the user and zoom to that location
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();  // Check if the location services are enabled
    if (!serviceEnabled) {
      return;
    }

    permission = await Geolocator.checkPermission();  // Check and request location permissions if needed
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition();  // Get the current location of the user
    LatLng userLocation = LatLng(position.latitude, position.longitude);

    _mapController.animateCamera(  // Move the map camera to the user's location
      CameraUpdate.newLatLngZoom(userLocation, 15),
    );

    _updateUserLocationMarker(userLocation);  // Update the user's location marker on the map

    setState(() {
      _isInfoWindowVisible = false;  // Hide the info window if it's open
    });

    _findSportsPlaces(userLocation);  // Find nearby basketball places
  }

  void _trackLocationChanges() {  // Track location changes and update the map markers accordingly
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,  // High accuracy for location updates
        distanceFilter: 10,  // Update every 10 meters
      ),
    ).listen((Position position) {
      LatLng newLocation = LatLng(position.latitude, position.longitude);
      _updateUserLocationMarker(newLocation);  // Update the user's location marker
      _findSportsPlaces(newLocation);  // Search for basketball places near the new location
    });
  }

  void _updateUserLocationMarker(LatLng location) {  // Update the marker for the user's location on the map
    setState(() {
      _markers.removeWhere((marker) => marker.markerId == const MarkerId('user_location'));  // Remove any existing user location marker
      _markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: location,
          icon: _userLocationIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      );
    });
  }

  void _onSearchIconPressed() {  // Toggle the visibility of the search bar when the search icon is pressed
    setState(() {
      _isSearchVisible = !_isSearchVisible;
    });
  }

  void _onMapCreated(GoogleMapController controller) {  // Callback when the Google Map is created
    _mapController = controller;
  }

  Future<void> _findSportsPlaces(LatLng location) async {  // Search for basketball places near the given location
    final response = await places.searchNearbyWithRadius(
      Location(lat: location.latitude, lng: location.longitude),
      5000,  // Search within a 5km radius
      keyword: "basketball",  // Search for basketball-related places
    );

    if (response.isOkay) {
      setState(() {
        _markers.removeWhere((marker) => marker.markerId != const MarkerId('user_location'));  // Remove all non-user-location markers
        for (var place in response.results) {
          _markers.add(
            Marker(
              markerId: MarkerId(place.placeId),
              position: LatLng(place.geometry!.location.lat, place.geometry!.location.lng),
              icon: _basketballMarkerIcon ?? BitmapDescriptor.defaultMarker,
              onTap: () {
                FocusScope.of(context).unfocus();  // Close the keyboard and show the info window for the selected marker
                _onMarkerTapped(place.placeId, LatLng(place.geometry!.location.lat, place.geometry!.location.lng));
              },
            ),
          );
        }
      });
    }
  }

  Future<void> _onMarkerTapped(String placeId, LatLng position) async {  // Show the info window for a marker when tapped
    final screenHeight = MediaQuery.of(context).size.height;  // Get screen dimensions before the async call
    final screenWidth = MediaQuery.of(context).size.width;

    final detail = await places.getDetailsByPlaceId(placeId);

    if (detail.isOkay) {
      final placeDetails = detail.result;
      final photoReference = placeDetails.photos.isNotEmpty ? placeDetails.photos[0].photoReference : null;
      final imageUrl = photoReference != null
          ? "https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=$photoReference&key=AIzaSyB-Auv39s_lM1kjpfOBySaQwxTMq5kfY-o"
          : 'https://via.placeholder.com/400';

      final adjustedPosition = LatLng(position.latitude + 0.001, position.longitude);  // Adjust the position slightly to center vertically

      await _mapController.animateCamera(  // Zoom and center the map on the marker's position
        CameraUpdate.newLatLngZoom(adjustedPosition, 16),
      );

      final infoWindowPosition = Offset(  // Position the info window on the screen (upper right quadrant)
        screenWidth * 0.55,  // Shift 60% from left to right
        screenHeight * 0.24,  // Shift 25% from top to bottom
      );

      if (mounted) {
        setState(() {
          _isSearchVisible = false;  // Hide the search bar
          _infoWindowTitle = placeDetails.name;  // Update the info window state with new data
          _infoWindowImage = imageUrl;
          _isInfoWindowVisible = true;
          _infoWindowPosition = infoWindowPosition;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final appBarHeight = screenHeight * 0.08;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          MapWidget(
            onMapCreated: _onMapCreated,
            markers: _markers,  // Pass markers to the MapWidget
          ),
          if (_isInfoWindowVisible && _infoWindowPosition != null)
            Positioned(
              left: _infoWindowPosition!.dx,
              top: _infoWindowPosition!.dy,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _isInfoWindowVisible ? 1.0 : 0.0,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),  // Round top left corner
                    topRight: Radius.circular(10),  // Round top right corner
                    bottomLeft: Radius.circular(10),  // Round bottom left corner
                    bottomRight: Radius.circular(10),  // Round bottom right corner
                  ),
                  child: Container(
                    width: 150,
                    height: 200,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Image.network(
                              _infoWindowImage,
                              width: double.infinity,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.image_not_supported);
                              },
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                _infoWindowTitle,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _isInfoWindowVisible = false;  // Close the info window
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.7),
                              ),
                              padding: const EdgeInsets.all(5),
                              child: const Icon(
                                Icons.close,
                                color: Colors.black,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenHeight * 0.015),
              child: Column(
                children: [
                  Container(
                    height: appBarHeight,
                    color: Colors.transparent,
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
                  if (_isSearchVisible)
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: SearchWidget(
                        isSearchVisible: _isSearchVisible,
                        onSearchIconPressed: _onSearchIconPressed,
                        mapController: _mapController,
                        onPlaceSelected: (LatLng selectedLocation) {
                          _mapController.animateCamera(
                            CameraUpdate.newLatLngZoom(selectedLocation, 15),
                          );
                          _findSportsPlaces(selectedLocation);
                        },
                        focusNode: _searchFocusNode,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        height: screenHeight * 0.09,
        color: Colors.white,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),  // Correctly using named argument 'padding'
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.add, color: Colors.black),
                iconSize: screenWidth * 0.1,
                onPressed: () {
                  // Action when add icon is pressed
                },
              ),
              IconButton(
                icon: const Icon(Icons.gps_fixed, color: Colors.black),
                iconSize: screenWidth * 0.1,
                onPressed: () async {
                  await _getUserLocation();  // Center the map on the current user location
                },
              ),
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.black),
                iconSize: screenWidth * 0.1,
                onPressed: () {
                  // Action when settings icon is pressed
                },
              ),
              IconButton(
                icon: const Icon(Icons.bug_report, color: Colors.red),
                iconSize: screenWidth * 0.1,
                onPressed: () {
                  Navigator.pushNamed(context, '/test_firestore');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
