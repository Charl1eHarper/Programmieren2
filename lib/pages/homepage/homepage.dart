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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isSearchVisible = false;
  bool _isInfoWindowVisible = false;
  double _ringRating = 0.0;
  double _netzRating = 0.0;
  double _platzRating = 0.0;

  late String _infoWindowTitle;
  late String _infoWindowImage;
  late String _infoWindowAddress;
  Offset? _infoWindowPosition;

  List<String> _imagesForDetailPage = [];
  final Set<Marker> _markers = {};
  late GoogleMapController _mapController;
  GoogleMapsPlaces places = GoogleMapsPlaces(apiKey: 'AIzaSyB-Auv39s_lM1kjpfOBySaQwxTMq5kfY-o');
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

  // Hier definierst du _onMapCreated und _onSearchIconPressed
  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _onSearchIconPressed() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
    });
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

  // Berechnung der Entfernung zwischen zwei Punkten (in Kilometern)
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

  // Hilfsfunktion zur Umrechnung von Grad in Radiant
  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  Future<void> _findSportsPlaces(LatLng location) async {
    // Erstelle ein Set für alle bereits geladenen placeIds
    Set<String> loadedPlaceIds = {};

    // 1. Suche Orte in Google Maps API
    final response = await places.searchNearbyWithRadius(
      Location(lat: location.latitude, lng: location.longitude),
      5000, // 5km radius
      keyword: "basketball",
    );

    // 2. Suche benutzerdefinierte Orte in Firestore innerhalb des 5km Radius
    final firestore = FirebaseFirestore.instance;
    final QuerySnapshot basketballCourtsSnapshot = await firestore.collection('basketball_courts').get();

    // Filtere Orte innerhalb eines 5km-Radius und überprüfe den Typ des `location`-Felds
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

    // 3. Bereite die Orte aus Firestore auf und füge sie als Marker hinzu
    setState(() {
      _markers.removeWhere((marker) => marker.markerId != const MarkerId('user_location'));

      // Google Maps Ergebnisse
      for (var place in response.results) {
        // Prüfe, ob die placeId bereits geladen wurde (entweder von Google Maps oder Firestore)
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

            // Speichern des Ortes in Firestore
            _savePlaceToFirebase(placeData);

            // Hinzufügen des Markers
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

            // Füge die placeId dem Set hinzu, um doppelte Marker zu verhindern
            loadedPlaceIds.add(place.placeId);
          }
        }
      }

      // Firestore Orte
      for (var doc in nearbyBasketballCourts) {
        final GeoPoint geoPoint = doc['location'];
        final String firestorePlaceId = doc['placeId'];

        // Prüfe, ob die placeId bereits von Google Maps geladen wurde
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

          // Füge die placeId dem Set hinzu, um doppelte Marker zu verhindern
          loadedPlaceIds.add(firestorePlaceId);
        }
      }
    });
  }


  // Saving the place to Firebase using placeId as the unique identifier
  Future<void> _savePlaceToFirebase(Map<String, dynamic> placeData) async {
    final String placeId = placeData['placeId']; // Ensure placeId is used
    final firestore = FirebaseFirestore.instance;

    // Check if the place already exists in Firestore
    final DocumentSnapshot placeDoc = await firestore.collection('basketball_courts').doc(placeId).get();

    if (!placeDoc.exists) {
      // Save the place to Firebase if it doesn't exist
      await firestore.collection('basketball_courts').doc(placeId).set({
        'placeId': placeId, // Explicitly store the placeId in the document
        'name': placeData['name'],
        'location': GeoPoint(placeData['latitude'], placeData['longitude']),
        'imageUrls': placeData['imageUrls'],
        'address': placeData['address'],
      });
    }
  }

  Future<void> _showRatingDialog(String placeId) async {
    double ringRating = 3.0; // Default rating
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
                          ringRating = rating; // Update Ring rating
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
                          netzRating = rating; // Update Netz rating
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
                          platzRating = rating; // Update Platz rating
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
                    Navigator.of(context).pop(); // Close the dialog without submitting
                  },
                ),
                TextButton(
                  child: const Text("Submit"),
                  onPressed: () async {
                    try {
                      // Save the rating to Firebase using placeId
                      await _saveRatingToFirebase(placeId, ringRating, netzRating, platzRating);

                      // Refresh the marker ratings to update the InfoWindow
                      await _refreshMarkerRatings(placeId);

                      // Show success message
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Bewertung abgegeben!')),
                      );

                      // Close the dialog
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

      // Berechnungen für die Kategorie "Ring"
      double newRingSum = (data['ratings']['ring']['sum_of_ratings'] ?? 0.0) + ringRating;
      int newRingCount = (data['ratings']['ring']['total_ratings'] ?? 0) + 1;
      double newRingAverage = newRingSum / newRingCount;

      // Berechnungen für die Kategorie "Netz"
      double newNetzSum = (data['ratings']['netz']['sum_of_ratings'] ?? 0.0) + netzRating;
      int newNetzCount = (data['ratings']['netz']['total_ratings'] ?? 0) + 1;
      double newNetzAverage = newNetzSum / newNetzCount;

      // Berechnungen für die Kategorie "Platz"
      double newPlatzSum = (data['ratings']['platz']['sum_of_ratings'] ?? 0.0) + platzRating;
      int newPlatzCount = (data['ratings']['platz']['total_ratings'] ?? 0) + 1;
      double newPlatzAverage = newPlatzSum / newPlatzCount;

      // Aktualisiere die Firestore-Dokumente mit den neuen Bewertungen
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
    double ringRating = 0.0;
    double netzRating = 0.0;
    double platzRating = 0.0;

    bool isGoogleDataLoaded = false;

    // Schritt 1: Versuche, die Daten von Google Places zu laden
    try {
      final placeDetails = await places.getDetailsByPlaceId(placeId);

      if (placeDetails.isOkay && placeDetails.result.photos.isNotEmpty) {
        name = placeDetails.result.name;
        address = placeDetails.result.formattedAddress ?? "Keine Adresse verfügbar";

        // Lade die Bilder von Google Places
        for (var photo in placeDetails.result.photos) {
          final photoReference = photo.photoReference;
          final imageUrl = "https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=$photoReference&key=AIzaSyB-Auv39s_lM1kjpfOBySaQwxTMq5kfY-o";
          imageUrls.add(imageUrl);
        }

        isGoogleDataLoaded = true; // Setze das Flag, dass Google-Daten geladen wurden
      }
    } catch (e) {
      // Fehlerbehandlung bei Google Places Datenabruf
    }

    // Schritt 2: Falls keine Google-Daten oder Bilder gefunden wurden, lade Firestore-Daten
    if (!isGoogleDataLoaded) {
      try {
        DocumentSnapshot placeDoc = await FirebaseFirestore.instance
            .collection('basketball_courts')
            .doc(placeId)
            .get();

        Map<String, dynamic>? data = placeDoc.data() as Map<String, dynamic>?;

        if (data != null) {
          name = data['name'] ?? 'Kein Name verfügbar';
          address = data['address'] ?? 'Keine Adresse verfügbar';

          // Verwende die Firestore-URL, wenn verfügbar
          imageUrls = List<String>.from(data['image_urls'] ?? ['https://via.placeholder.com/400']);

          ringRating = data['ratings']?['ring']?['average'] ?? 0.0;
          netzRating = data['ratings']?['netz']?['average'] ?? 0.0;
          platzRating = data['ratings']?['platz']?['average'] ?? 0.0;
        } else {
          imageUrls.add('https://via.placeholder.com/400');
        }
      } catch (e) {
        // Fehlerbehandlung bei Firestore-Datenabruf
        imageUrls.add('https://via.placeholder.com/400');
      }
    }

    // Falls keine Bilder vorhanden sind, füge einen Platzhalter hinzu
    if (imageUrls.isEmpty) {
      imageUrls.add('https://via.placeholder.com/400');
    }

    final adjustedPosition = LatLng(position.latitude + 0.0028, position.longitude + 0.0015);

    await _mapController.animateCamera(
      CameraUpdate.newLatLngZoom(adjustedPosition, 16),
    );

    final infoWindowPosition = Offset(screenWidth * 0.36, screenHeight * 0.21);

    if (mounted) {
      setState(() {
        _ringRating = ringRating;
        _netzRating = netzRating;
        _platzRating = platzRating;

        _isSearchVisible = false;
        _infoWindowTitle = name;
        _infoWindowImage = imageUrls.isNotEmpty ? imageUrls[0] : 'https://via.placeholder.com/400';
        _infoWindowAddress = address;
        _isInfoWindowVisible = true;
        _infoWindowPosition = infoWindowPosition;
        _imagesForDetailPage = imageUrls;
        _selectedMarkerId = placeId;

        // Update marker state
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
                            placeId: _selectedMarkerId!,  // Use _selectedMarkerId here
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
                    _showRatingDialog(_selectedMarkerId!);  // Show rating dialog
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
