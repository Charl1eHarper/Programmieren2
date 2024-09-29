import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hoophub/pages/homepage/map_widget.dart';
import 'package:hoophub/pages/homepage/search_widget.dart';
import 'package:hoophub/pages/homepage/marker_details_page.dart';
import 'package:hoophub/pages/homepage/info_window_widget.dart';
import 'package:hoophub/pages/homepage/add_court_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  late String _infoWindowAddress;
  Offset? _infoWindowPosition;

  List<String> _imagesForDetailPage = [];

  final Set<Marker> _markers = {};
  late GoogleMapController _mapController;
  GoogleMapsPlaces places = GoogleMapsPlaces(
      apiKey: 'AIzaSyB-Auv39s_lM1kjpfOBySaQwxTMq5kfY-o');

  final FocusNode _searchFocusNode = FocusNode();
  StreamSubscription<Position>? _positionStream;

  BitmapDescriptor? _userLocationIcon;
  BitmapDescriptor? _basketballMarkerIcon;
  BitmapDescriptor? _selectedBasketballMarkerIcon;

  String? _selectedMarkerId;

  @override
  void initState() {
    super.initState();

    _searchFocusNode.addListener(() {
      if (_searchFocusNode.hasFocus) {
        setState(() {
          _isInfoWindowVisible = false;
          _onCloseInfoWindow();
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
      const ImageConfiguration(size: Size(64, 64)),
      'assets/user_location_icon.png',
    );

    _basketballMarkerIcon = await BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(45, 45)),
      'assets/basketball_marker.png',
    );

    _selectedBasketballMarkerIcon = await BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(45, 45)),
      'assets/selected_basketball_marker.png',
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
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition();
    LatLng userLocation = LatLng(position.latitude, position.longitude);

    _mapController.animateCamera(
      CameraUpdate.newLatLngZoom(userLocation, 15),
    );

    _updateUserLocationMarker(userLocation);

    setState(() {
      _isInfoWindowVisible = false;
    });

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

      if (_isSearchVisible) {
        _onCloseInfoWindow();
        _isInfoWindowVisible = false;
        _selectedMarkerId = null;
      }
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  // Funktion zum Speichern von Plätzen in Firebase
  Future<void> _savePlaceToFirebase(Map<String, dynamic> placeData) async {
    final String placeId = placeData['placeId'];
    final firestore = FirebaseFirestore.instance;

    // Überprüfen, ob der Platz bereits in Firestore existiert
    final DocumentSnapshot placeDoc = await firestore.collection('basketball_courts').doc(placeId).get();

    if (!placeDoc.exists) {
      // Platz noch nicht vorhanden, also speichern
      await firestore.collection('basketball_courts').doc(placeId).set({
        'name': placeData['name'],
        'location': GeoPoint(placeData['latitude'], placeData['longitude']),
        'imageUrls': placeData['imageUrls'],
        'address': placeData['address'],
      });
    }
  }

  Future<void> _findSportsPlaces(LatLng location) async {
    final response = await places.searchNearbyWithRadius(
      Location(lat: location.latitude, lng: location.longitude),
      5000, // Radius von 5 km
      keyword: "basketball",
    );

    if (response.isOkay) {
      setState(() {
        _markers.removeWhere((marker) => marker.markerId != const MarkerId('user_location'));

        for (var place in response.results) {
          if (!place.types.contains("store") && !place.types.contains("gym")) {
            var placeData = {
              'placeId': place.placeId,
              'name': place.name,
              'latitude': place.geometry!.location.lat,
              'longitude': place.geometry!.location.lng,
              'address': place.vicinity,
              'imageUrls': place.photos.isNotEmpty
                  ? place.photos.map((photo) => "https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=${photo.photoReference}&key=YOUR_API_KEY").toList()
                  : ['https://via.placeholder.com/400'],
            };

            // Speichere den Platz in Firebase, falls er noch nicht existiert
            _savePlaceToFirebase(placeData);

            // Füge den Marker zur Karte hinzu
            _markers.add(
              Marker(
                markerId: MarkerId(place.placeId),
                position: LatLng(place.geometry!.location.lat, place.geometry!.location.lng),
                icon: _basketballMarkerIcon ?? BitmapDescriptor.defaultMarker,
                onTap: () {
                  _onMarkerTapped(place.placeId, LatLng(place.geometry!.location.lat, place.geometry!.location.lng));
                },
              ),
            );
          }
        }
      });
    }
  }

  Future<void> _onMarkerTapped(String placeId, LatLng position) async {
    if (_selectedMarkerId != null && _selectedMarkerId != placeId) {
      _onCloseInfoWindow();
    }

    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final detail = await places.getDetailsByPlaceId(placeId);

    if (detail.isOkay) {
      final placeDetails = detail.result;

      List<String> imageUrls = [];
      if (placeDetails.photos.isNotEmpty) {
        for (var photo in placeDetails.photos) {
          final photoReference = photo.photoReference;
          final imageUrl = "https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=$photoReference&key=AIzaSyB-Auv39s_lM1kjpfOBySaQwxTMq5kfY-o";
          imageUrls.add(imageUrl);
        }
      } else {
        imageUrls.add('https://via.placeholder.com/400');
      }

      final adjustedPosition = LatLng(
          position.latitude + 0.0028, position.longitude + 0.0015);

      await _mapController.animateCamera(
        CameraUpdate.newLatLngZoom(adjustedPosition, 16),
      );

      final infoWindowPosition = Offset(
        screenWidth * 0.36,
        screenHeight * 0.21,
      );

      _infoWindowAddress = placeDetails.formattedAddress ?? "Adresse nicht verfügbar";

      if (mounted) {
        setState(() {
          _isSearchVisible = false;
          _infoWindowTitle = placeDetails.name;
          _infoWindowImage = imageUrls.isNotEmpty
              ? imageUrls[0]
              : 'https://via.placeholder.com/400';
          _isInfoWindowVisible = true;
          _infoWindowPosition = infoWindowPosition;
          _imagesForDetailPage = imageUrls;
          _selectedMarkerId = placeId;

          _markers.removeWhere((marker) => marker.markerId == MarkerId(placeId));
          _markers.add(
            Marker(
              markerId: MarkerId(placeId),
              position: position,
              icon: _selectedBasketballMarkerIcon!,
              onTap: () {
                FocusScope.of(context).unfocus();
                _onMarkerTapped(placeId, position);
              },
            ),
          );
        });
      }
    }
  }

  void _onCloseInfoWindow() {
    if (_selectedMarkerId != null) {
      final updatedMarkers = _markers.map((marker) {
        if (marker.markerId.value == _selectedMarkerId) {
          return marker.copyWith(
            iconParam: _basketballMarkerIcon!,
          );
        }
        return marker;
      }).toSet();

      setState(() {
        _markers.clear();
        _markers.addAll(updatedMarkers);
      });

      _selectedMarkerId = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final appBarHeight = screenHeight * 0.08;

    return Scaffold(
      resizeToAvoidBottomInset: false,
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
                child: InfoWindowWidget(
                  title: _infoWindowTitle,
                  imageUrl: _infoWindowImage,
                  onShowMorePressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MarkerDetailsPage(
                          markerName: _infoWindowTitle,
                          markerAddress: _infoWindowAddress,
                          images: _imagesForDetailPage,
                          peoplePerHour: const {
                            12: 4,
                            13: 6,
                            14: 3,
                            15: 8,
                            16: 5,
                            17: 9,
                            18: 4,
                            19: 7,
                          },
                        ),
                      ),
                    );
                  },
                  onClosePressed: () {
                    setState(() {
                      _onCloseInfoWindow();
                      _isInfoWindowVisible = false;
                      _selectedMarkerId = null;
                    });
                  },
                  onAddRatingPressed: () {
                    // Add your logic for handling user rating submission here
                  },
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
                                Navigator.pushNamed(context, '/account');
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AddCourtPage()),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.gps_fixed, color: Colors.black),
                iconSize: screenWidth * 0.1,
                onPressed: () async {
                  await _getUserLocation();

                  setState(() {
                    _onCloseInfoWindow();
                    _isInfoWindowVisible = false;
                    _selectedMarkerId = null;
                  });
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
