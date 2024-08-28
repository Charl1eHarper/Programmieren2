import 'dart:async'; // Importiere dart:async für StreamSubscription
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:geolocator/geolocator.dart'; // Importiere Geolocator
import 'package:hoophub/pages/homepage/map_widget.dart';
import 'package:hoophub/pages/homepage/search_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isSearchVisible = false;
  bool _isInfoWindowVisible = false;
  late String _infoWindowTitle;
  late String _infoWindowImage;

  final Set<Marker> _markers = {};
  late GoogleMapController _mapController;
  GoogleMapsPlaces places = GoogleMapsPlaces(apiKey: 'AIzaSyB-Auv39s_lM1kjpfOBySaQwxTMq5kfY-o');

  final FocusNode _searchFocusNode = FocusNode();
  StreamSubscription<Position>? _positionStream;
  LatLng? _currentLocation;

  @override
  void initState() {
    super.initState();

    _searchFocusNode.addListener(() {
      if (_searchFocusNode.hasFocus) {
        setState(() {
          _isInfoWindowVisible = false; // Schließt das InfoWindow, wenn die Tastatur geöffnet wird
        });
      }
    });

    _getUserLocation(initial: true); // Benutzerposition beim Start abrufen und zentrieren
    _trackLocationChanges(); // Startet das Tracking der Standortänderungen
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _getUserLocation({bool initial = false}) async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition();
    LatLng userLocation = LatLng(position.latitude, position.longitude);

    if (initial) {
      _mapController.animateCamera(
        CameraUpdate.newLatLngZoom(userLocation, 15),
      );
    }

    _currentLocation = userLocation;
    _updateUserLocationMarker(userLocation);
    _findSportsPlaces(userLocation);
  }

  void _trackLocationChanges() {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Mindestabstand in Metern, bevor ein Update erfolgt
      ),
    ).listen((Position position) {
      LatLng newLocation = LatLng(position.latitude, position.longitude);
      _currentLocation = newLocation;
      _updateUserLocationMarker(newLocation);
      _findSportsPlaces(newLocation); // Automatische Suche bei Standortänderung
    });
  }

  void _updateUserLocationMarker(LatLng location) {
    setState(() {
      _markers.removeWhere((marker) => marker.markerId == const MarkerId('user_location'));
      _markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: location,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue), // Verwendet das standardmäßige blaue Symbol
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      );
    });
  }

  void _onSearchIconPressed() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  Future<void> _findSportsPlaces(LatLng location) async {
    PlacesSearchResponse response = await places.searchNearbyWithRadius(
      Location(lat: location.latitude, lng: location.longitude),
      5000, // 5km Radius
      keyword: "basketball",
    );

    if (response.isOkay) {
      setState(() {
        _markers.removeWhere((marker) => marker.markerId != const MarkerId('user_location'));
        for (var place in response.results) {
          _markers.add(
            Marker(
              markerId: MarkerId(place.placeId),
              position: LatLng(place.geometry!.location.lat, place.geometry!.location.lng),
              onTap: () {
                FocusScope.of(context).unfocus(); // Schließt die Tastatur
                _onMarkerTapped(place.placeId, LatLng(place.geometry!.location.lat, place.geometry!.location.lng));
              },
            ),
          );
        }
      });
    }
  }

  Future<void> _onMarkerTapped(String placeId, LatLng position) async {
    PlacesDetailsResponse detail = await places.getDetailsByPlaceId(placeId);

    if (detail.isOkay) {
      final placeDetails = detail.result;
      final photoReference = placeDetails.photos.isNotEmpty ? placeDetails.photos[0].photoReference : null;
      final imageUrl = photoReference != null
          ? "https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=$photoReference&key=AIzaSyB-Auv39s_lM1kjpfOBySaQwxTMq5kfY-o"
          : 'https://via.placeholder.com/400'; // Platzhalterbild

      setState(() {
        _isInfoWindowVisible = true;
        _infoWindowTitle = placeDetails.name;
        _infoWindowImage = imageUrl;
      });
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
          // Map in the background
          MapWidget(
            onMapCreated: _onMapCreated,
            markers: _markers,
          ),
          if (_isInfoWindowVisible)
            Positioned(
              left: screenWidth * 0.2,
              bottom: screenHeight * 0.3,
              child: Container(
                width: 200,
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
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
                          height: 150,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.image_not_supported); // Platzhalter-Icon bei Fehler
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
                            _isInfoWindowVisible = false; // Schließt das InfoWindow
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.7), // Weißer transparenter Kreis
                          ),
                          padding: const EdgeInsets.all(5),
                          child: const Icon(
                            Icons.close,
                            color: Colors.black,
                            size: 20, // Größe des X-Symbols
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // AppBar and SearchBar
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
                        focusNode: _searchFocusNode, // FocusNode übergeben
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
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
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
                onPressed: () => _getUserLocation(), // Benutzerstandort manuell abrufen und zentrieren
              ),
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.black),
                iconSize: screenWidth * 0.1,
                onPressed: () {
                  // Action when settings icon is pressed
                },
              ),
              // Add the test navigation button here
              IconButton(
                icon: const Icon(Icons.bug_report, color: Colors.red), // Icon for the test page
                iconSize: screenWidth * 0.1,
                onPressed: () {
                  Navigator.pushNamed(context, '/test_firestore'); // Navigate to TestFirestorePage
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
