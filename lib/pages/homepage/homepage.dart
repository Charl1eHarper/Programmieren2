import 'dart:async';
import 'dart:math';
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
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

// Check if the user is logged in as a guest
bool _isGuestUser() {
  User? user = FirebaseAuth.instance.currentUser;
  return user != null && user.isAnonymous;
}

class _HomePageState extends State<HomePage> {
  bool _isSearchVisible = false; // Toggle for showing search bar
  bool _isInfoWindowVisible = false; // Toggle for showing info window
  double _ringRating = 0.0;
  double _netzRating = 0.0;
  double _platzRating = 0.0;

  late String _infoWindowTitle; // Info window title for markers
  late String _infoWindowImage; // Info window image URL
  late String _infoWindowAddress; // Info window address
  Offset? _infoWindowPosition; // Position for the info window

  List<String> _imagesForDetailPage = []; // Store images for detail page
  final Set<Marker> _markers = {}; // Set of map markers
  late GoogleMapController _mapController;
  GoogleMapsPlaces places = GoogleMapsPlaces(apiKey: 'AIzaSyB-Auv39s_lM1kjpfOBySaQwxTMq5kfY-o');
  final FocusNode _searchFocusNode = FocusNode(); // Focus node for search bar
  StreamSubscription<Position>? _positionStream; // Stream to track location changes

  BitmapDescriptor? _userLocationIcon; // Custom icon for user location
  BitmapDescriptor? _basketballMarkerIcon; // Custom icon for basketball court
  BitmapDescriptor? _selectedBasketballMarkerIcon; // Custom icon for selected marker
  String? _selectedMarkerId; // Track the selected marker

  @override
  void initState() {
    super.initState();

    // Hide the info window when search bar is focused
    _searchFocusNode.addListener(() {
      if (_searchFocusNode.hasFocus) {
        setState(() {
          _isInfoWindowVisible = false;
          _onCloseInfoWindow();
        });
      }
    });

    // Load custom marker icons and get the user's initial location
    _loadCustomMarkers();
    _getUserLocation(initial: true);
    _trackLocationChanges(); // Start tracking user location
  }

  @override
  void dispose() {
    _positionStream?.cancel(); // Stop location stream when widget is disposed
    _searchFocusNode.dispose(); // Dispose search focus node
    super.dispose();
  }

  // Handle Google Map creation
  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  // Toggle the visibility of the search bar
  void _onSearchIconPressed() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
    });
  }

  // Load custom icons for map markers
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

  // Get the user's current location
  Future<void> _getUserLocation({bool initial = false}) async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    // Request necessary location permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
        return;
      }
    }

    // Fetch current user location
    Position position = await Geolocator.getCurrentPosition();
    LatLng userLocation = LatLng(position.latitude, position.longitude);

    // Move the camera to the user's location
    _mapController.animateCamera(
      CameraUpdate.newLatLngZoom(userLocation, 15),
    );

    // Add a marker for the user's location
    _updateUserLocationMarker(userLocation);

    setState(() {
      _isInfoWindowVisible = false; // Hide the info window after updating location
    });

    _findSportsPlaces(userLocation); // Find nearby basketball courts
  }

  // Track changes in the user's location
  void _trackLocationChanges() {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update location when moved more than 10 meters
      ),
    ).listen((Position position) {
      LatLng newLocation = LatLng(position.latitude, position.longitude);
      _updateUserLocationMarker(newLocation);
      _findSportsPlaces(newLocation); // Refresh nearby courts when location changes
    });
  }

  // Add or update a marker for the user's current location
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

  // Calculate distance between two locations in kilometers
  double _calculateDistance(LatLng start, LatLng end) {
    const double earthRadiusKm = 6371.0;

    final double dLat = _degreesToRadians(end.latitude - start.latitude);
    final double dLng = _degreesToRadians(end.longitude - start.longitude);

    final double lat1 = _degreesToRadians(start.latitude);
    final double lat2 = _degreesToRadians(end.latitude);

    final double a = (sin(dLat / 2) * sin(dLat / 2)) +
        (sin(dLng / 2) * sin(dLng / 2) * cos(lat1) * cos(lat2));
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadiusKm * c;
  }

  // Convert degrees to radians
  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  // Find nearby basketball courts using Google Places API and Firestore
  Future<void> _findSportsPlaces(LatLng location) async {
    Set<String> loadedPlaceIds = {}; // Set to avoid duplicate markers

    // Fetch places using Google Maps API (within 5km radius)
    final response = await places.searchNearbyWithRadius(
      Location(lat: location.latitude, lng: location.longitude),
      5000, // 5km radius
      keyword: "basketball",
    );

    // Fetch custom places from Firestore
    final firestore = FirebaseFirestore.instance;
    final QuerySnapshot basketballCourtsSnapshot = await firestore.collection('basketball_courts').get();

    // Filter Firestore results within 5km radius
    List<QueryDocumentSnapshot> nearbyBasketballCourts = basketballCourtsSnapshot.docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>?;

      if (data != null && data.containsKey('location')) {
        final dynamic locationField = data['location'];

        if (locationField is GeoPoint) {
          final LatLng courtLocation = LatLng(locationField.latitude, locationField.longitude);
          return _calculateDistance(location, courtLocation) <= 5.0;
        }
      }
      return false;
    }).toList();

    // Add markers to the map
    setState(() {
      _markers.removeWhere((marker) => marker.markerId != const MarkerId('user_location'));

      // Add Google Maps API results as markers
      for (var place in response.results) {
        if (!loadedPlaceIds.contains(place.placeId)) {
          if (!place.types.contains("store") && !place.types.contains("gym")) {
            var placeData = {
              'placeId': place.placeId,
              'name': place.name,
              'latitude': place.geometry!.location.lat,
              'longitude': place.geometry!.location.lng,
              'address': place.vicinity,
              'imageUrls': place.photos.isNotEmpty
                  ? place.photos.map((photo) => "https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=${photo.photoReference}&key=AIzaSyB-Auv39s_lM1kjpfOBySaQwxTMq5kfY-o").toList()
                  : ['https://via.placeholder.com/400'],
            };

            _savePlaceToFirebase(placeData); // Save to Firestore

            // Add marker for the place
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

            loadedPlaceIds.add(place.placeId); // Prevent duplicate markers
          }
        }
      }

      // Add Firestore results as markers
      for (var doc in nearbyBasketballCourts) {
        final GeoPoint geoPoint = doc['location'];
        final String firestorePlaceId = doc['placeId'];

        if (!loadedPlaceIds.contains(firestorePlaceId)) {
          _markers.add(
            Marker(
              markerId: MarkerId(firestorePlaceId),
              position: LatLng(geoPoint.latitude, geoPoint.longitude),
              icon: _basketballMarkerIcon ?? BitmapDescriptor.defaultMarker,
              onTap: () {
                _onMarkerTapped(firestorePlaceId, LatLng(geoPoint.latitude, geoPoint.longitude));
              },
            ),
          );

          loadedPlaceIds.add(firestorePlaceId);
        }
      }
    });
  }

  // Save place data to Firestore if it doesn't already exist
  Future<void> _savePlaceToFirebase(Map<String, dynamic> placeData) async {
    final String placeId = placeData['placeId'];
    final firestore = FirebaseFirestore.instance;

    // Check if the place exists in Firestore
    final DocumentSnapshot placeDoc = await firestore.collection('basketball_courts').doc(placeId).get();

    if (!placeDoc.exists) {
      // Save place to Firestore
      await firestore.collection('basketball_courts').doc(placeId).set({
        'placeId': placeId,
        'name': placeData['name'],
        'location': GeoPoint(placeData['latitude'], placeData['longitude']),
        'imageUrls': placeData['imageUrls'],
        'address': placeData['address'],
      });
    }
  }

  // Show rating dialog for a specific place
  Future<void> _showRatingDialog(String placeId) async {
    double ringRating = 3.0;
    double netzRating = 3.0;
    double platzRating = 3.0;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Bewerte diesen Platz'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Ring"),
                    RatingBar.builder(
                      initialRating: ringRating,
                      minRating: 1,
                      allowHalfRating: true,
                      itemCount: 5,
                      itemBuilder: (context, _) => const Icon(
                        Icons.star,
                        color: Colors.amber,
                      ),
                      onRatingUpdate: (rating) {
                        setState(() {
                          ringRating = rating;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text("Netz"),
                    RatingBar.builder(
                      initialRating: netzRating,
                      minRating: 1,
                      allowHalfRating: true,
                      itemCount: 5,
                      itemBuilder: (context, _) => const Icon(
                        Icons.star,
                        color: Colors.amber,
                      ),
                      onRatingUpdate: (rating) {
                        setState(() {
                          netzRating = rating;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text("Platz"),
                    RatingBar.builder(
                      initialRating: platzRating,
                      minRating: 1,
                      allowHalfRating: true,
                      itemCount: 5,
                      itemBuilder: (context, _) => const Icon(
                        Icons.star,
                        color: Colors.amber,
                      ),
                      onRatingUpdate: (rating) {
                        setState(() {
                          platzRating = rating;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text("Abbrechen"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text("Submit"),
                  onPressed: () async {
                    try {
                      // Save the rating to Firebase
                      await _saveRatingToFirebase(placeId, ringRating, netzRating, platzRating);

                      // Refresh marker ratings
                      await _refreshMarkerRatings(placeId);

                      // Show success message
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Bewertung abgegeben!')),
                      );

                      Navigator.of(context).pop();
                    } catch (e) {
                      // Show error message
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Bewertung fehlerhaft')),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Refresh marker ratings from Firestore
  Future<void> _refreshMarkerRatings(String placeId) async {
    final DocumentSnapshot placeDoc = await FirebaseFirestore.instance
        .collection('basketball_courts')
        .doc(placeId)
        .get();

    Map<String, dynamic>? data = placeDoc.data() as Map<String, dynamic>?;

    if (data != null) {
      double ringRatingFB = data['ratings']?['ring']?['average'] ?? 0.0;
      double netzRatingFB = data['ratings']?['netz']?['average'] ?? 0.0;
      double platzRatingFB = data['ratings']?['platz']?['average'] ?? 0.0;

      if (mounted) {
        setState(() {
          _ringRating = ringRatingFB;
          _netzRating = netzRatingFB;
          _platzRating = platzRatingFB;
        });
      }
    }
  }

  // Save rating data to Firestore
  Future<void> _saveRatingToFirebase(
      String placeId, double ringRating, double netzRating, double platzRating) async {
    final firestore = FirebaseFirestore.instance;
    final DocumentReference placeDocRef = firestore.collection('basketball_courts').doc(placeId);
    final DocumentSnapshot placeDoc = await placeDocRef.get();

    if (placeDoc.exists) {
      Map<String, dynamic> data = placeDoc.data() as Map<String, dynamic>;

      if (data['ratings'] == null) {
        data['ratings'] = {
          'ring': {'total_ratings': 0, 'sum_of_ratings': 0.0, 'average': 0.0},
          'netz': {'total_ratings': 0, 'sum_of_ratings': 0.0, 'average': 0.0},
          'platz': {'total_ratings': 0, 'sum_of_ratings': 0.0, 'average': 0.0}
        };
      }

      // Update ring rating
      double newRingSum = (data['ratings']['ring']['sum_of_ratings'] ?? 0.0) + ringRating;
      int newRingCount = (data['ratings']['ring']['total_ratings'] ?? 0) + 1;
      double newRingAverage = newRingSum / newRingCount;

      // Update netz rating
      double newNetzSum = (data['ratings']['netz']['sum_of_ratings'] ?? 0.0) + netzRating;
      int newNetzCount = (data['ratings']['netz']['total_ratings'] ?? 0) + 1;
      double newNetzAverage = newNetzSum / newNetzCount;

      // Update platz rating
      double newPlatzSum = (data['ratings']['platz']['sum_of_ratings'] ?? 0.0) + platzRating;
      int newPlatzCount = (data['ratings']['platz']['total_ratings'] ?? 0) + 1;
      double newPlatzAverage = newPlatzSum / newPlatzCount;

      // Save updated ratings to Firestore
      await placeDocRef.update({
        'ratings.ring': {
          'total_ratings': newRingCount,
          'sum_of_ratings': newRingSum,
          'average': newRingAverage
        },
        'ratings.netz': {
          'total_ratings': newNetzCount,
          'sum_of_ratings': newNetzSum,
          'average': newNetzAverage
        },
        'ratings.platz': {
          'total_ratings': newPlatzCount,
          'sum_of_ratings': newPlatzSum,
          'average': newPlatzAverage
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

    List<String> imageUrls = [];
    String name = '';
    String address = '';

    bool isGoogleDataLoaded = false;

    // Try loading data from Google Places
    try {
      final placeDetails = await places.getDetailsByPlaceId(placeId);

      if (placeDetails.isOkay) {
        name = placeDetails.result.name;
        address = placeDetails.result.formattedAddress ?? "Keine Adresse verfügbar";

        // Check if Google Places has any images
        if (placeDetails.result.photos.isNotEmpty) {
          for (var photo in placeDetails.result.photos) {
            final photoReference = photo.photoReference;
            final imageUrl =
                "https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=$photoReference&key=AIzaSyB-Auv39s_lM1kjpfOBySaQwxTMq5kfY-o";
            imageUrls.add(imageUrl);
          }
        }

        isGoogleDataLoaded = true;
      }
    } catch (e) {
      // Handle Google Places errors

    }

    // No Google data, load from Firestore
    if (!isGoogleDataLoaded || imageUrls.isEmpty) {
      try {
        DocumentSnapshot placeDoc = await FirebaseFirestore.instance
            .collection('basketball_courts')
            .doc(placeId)
            .get();

        Map<String, dynamic>? data = placeDoc.data() as Map<String, dynamic>?;

        if (data != null) {
          // Load images from Firestore if available
          if (data.containsKey('image_urls')) {
            imageUrls = List<String>.from(data['image_urls']);
          }

          // Load name and address from Firestore
          name = data['name'] ?? 'Kein Name verfügbar';
          address = data['address'] ?? 'Keine Adresse verfügbar';
        }
      } catch (e) {
        // Handle Firestore errors

      }
    }

    // no images available, add a placeholder image
    if (imageUrls.isEmpty) {
      imageUrls.add('https://via.placeholder.com/400');
    }

    // Adjust the position of the map camera to show info window
    final adjustedPosition = LatLng(position.latitude + 0.0028, position.longitude + 0.0015);

    await _mapController.animateCamera(
      CameraUpdate.newLatLngZoom(adjustedPosition, 16),
    );

    final infoWindowPosition = Offset(screenWidth * 0.36, screenHeight * 0.21);

    // Fetch ratings from Firestore
    await _refreshMarkerRatings(placeId);

    if (mounted) {
      setState(() {
        _infoWindowTitle = name;
        _infoWindowImage = imageUrls.isNotEmpty ? imageUrls[0] : 'https://via.placeholder.com/400';
        _infoWindowAddress = address;
        _isInfoWindowVisible = true;
        _infoWindowPosition = infoWindowPosition;
        _imagesForDetailPage = imageUrls;
        _selectedMarkerId = placeId;

        // Close the search bar if it's visible
        _isSearchVisible = false;

        // Change marker appearance when selected
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


  // Close the info window and reset the marker appearance
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

  // Show dialog to inform users about restricted access for guests
  void _showRestrictedAccessDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Access Restricted'),
          content: const Text('Please create an account to access this feature.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  '/landing',
                );
              },
              child: const Text('Create Account'),
            ),
          ],
        );
      },
    );
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
                  ringRating: _ringRating,
                  netzRating: _netzRating,
                  platzRating: _platzRating,
                  onShowMorePressed: () {
                    if (_selectedMarkerId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MarkerDetailsPage(
                            markerName: _infoWindowTitle,
                            markerAddress: _infoWindowAddress,
                            images: _imagesForDetailPage,
                            placeId: _selectedMarkerId!,
                          ),
                        ),
                      );
                    }
                  },
                  onClosePressed: () {
                    setState(() {
                      _onCloseInfoWindow();
                      _isInfoWindowVisible = false;
                      _selectedMarkerId = null;
                    });
                  },
                  onAddRatingPressed: () {
                    _showRatingDialog(_selectedMarkerId!); // Show rating dialog
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
                              icon:
                              const Icon(Icons.people, color: Colors.black),
                              iconSize: screenWidth * 0.1,
                              onPressed: () {
                                // Handle guest user access restriction
                                if (_isGuestUser()) {
                                  _showRestrictedAccessDialog();
                                } else {
                                  Navigator.pushNamed(context, '/community');
                                }
                              },
                            ),
                          ),
                          Center(
                            child: IconButton(
                              icon: const Icon(Icons.account_circle,
                                  color: Colors.black),
                              iconSize: screenWidth * 0.1,
                              onPressed: () {
                                if (_isGuestUser()) {
                                  _showRestrictedAccessDialog();
                                } else {
                                  Navigator.pushNamed(context, '/account');
                                }
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
                    MaterialPageRoute(builder: (context) => const AddCourtPage()),
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
            ],
          ),
        ),
      ),
    );
  }
}
