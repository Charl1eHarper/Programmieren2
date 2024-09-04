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
  bool _isSearchVisible = false;
  bool _isInfoWindowVisible = false;
  late String _infoWindowTitle;
  late String _infoWindowImage;
  Offset? _infoWindowPosition;  // Deklaration der fehlenden Variable

  final Set<Marker> _markers = {};
  late GoogleMapController _mapController;
  GoogleMapsPlaces places = GoogleMapsPlaces(apiKey: 'AIzaSyB-Auv39s_lM1kjpfOBySaQwxTMq5kfY-o');

  final FocusNode _searchFocusNode = FocusNode();
  StreamSubscription<Position>? _positionStream;

  BitmapDescriptor? _userLocationIcon;
  BitmapDescriptor? _basketballMarkerIcon;

  @override
  void initState() {
    super.initState();

    _searchFocusNode.addListener(() {
      if (_searchFocusNode.hasFocus) {
        setState(() {
          _isInfoWindowVisible = false;
        });
      }
    });

    _loadCustomMarkers();
    _getUserLocation(initial: true);
    _trackLocationChanges();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadCustomMarkers() async {
    _userLocationIcon = await BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/user_location_icon.png',
    );

    _basketballMarkerIcon = await BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(30, 30)),
      'assets/basketball_marker.png',
    );
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

    _mapController.animateCamera(
      CameraUpdate.newLatLngZoom(userLocation, 15),
    );

    _updateUserLocationMarker(userLocation);
    _findSportsPlaces(userLocation);
  }

  void _trackLocationChanges() {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      LatLng newLocation = LatLng(position.latitude, position.longitude);
      _updateUserLocationMarker(newLocation);
      _findSportsPlaces(newLocation);
    });
  }

  void _updateUserLocationMarker(LatLng location) {
    setState(() {
      _markers.removeWhere((marker) => marker.markerId == const MarkerId('user_location'));
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

  void _onSearchIconPressed() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  Future<void> _findSportsPlaces(LatLng location) async {
    final response = await places.searchNearbyWithRadius(
      Location(lat: location.latitude, lng: location.longitude),
      5000,
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
              icon: _basketballMarkerIcon ?? BitmapDescriptor.defaultMarker,
              onTap: () {
                FocusScope.of(context).unfocus();
                _onMarkerTapped(place.placeId, LatLng(place.geometry!.location.lat, place.geometry!.location.lng));
              },
            ),
          );
        }
      });
    }
  }

  Future<void> _onMarkerTapped(String placeId, LatLng position) async {
    // Berechne screenHeight und screenWidth vor dem asynchronen Aufruf
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final detail = await places.getDetailsByPlaceId(placeId);

    if (detail.isOkay) {
      final placeDetails = detail.result;
      final photoReference = placeDetails.photos.isNotEmpty ? placeDetails.photos[0].photoReference : null;
      final imageUrl = photoReference != null
          ? "https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=$photoReference&key=AIzaSyB-Auv39s_lM1kjpfOBySaQwxTMq5kfY-o"
          : 'https://via.placeholder.com/400';

      // Hier wird der Marker weiter unten als vertikal zentral positioniert
      final adjustedPosition = LatLng(position.latitude + 0.001, position.longitude);

      // Kamera zoomen und auf die neue Position zentrieren
      await _mapController.animateCamera(
        CameraUpdate.newLatLngZoom(adjustedPosition, 16),
      );

      // Position des Infofensters in der oberen Bildschirmhälfte rechts
      final infoWindowPosition = Offset(
        screenWidth * 0.55,  // 60% des Bildschirms von links nach rechts verschoben
        screenHeight * 0.24,  // 25% des Bildschirms von oben nach unten verschoben (obere Bildschirmhälfte)
      );

      if (mounted) {
        setState(() {
          // Schließe die Suchleiste
          _isSearchVisible = false;

          // Aktualisiere den Infowindow Zustand
          _infoWindowTitle = placeDetails.name;
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
            markers: _markers,
          ),
          if (_isInfoWindowVisible && _infoWindowPosition != null)
            Positioned(
              left: _infoWindowPosition!.dx,
              top: _infoWindowPosition!.dy,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _isInfoWindowVisible ? 1.0 : 0.0,
                child: Container(
                  width: 150,
                  height: 200,
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
                              _isInfoWindowVisible = false;
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
                onPressed: () async {
                  await _getUserLocation(); // Kamera auf aktuellen Standort zentrieren
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
