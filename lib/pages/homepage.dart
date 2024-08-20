import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart'; // For Google Places API

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late GoogleMapController mapController;
  final LatLng _center = const LatLng(45.521563, -122.677433);
  bool _isSearchVisible = false; // Control visibility of search bar
  final TextEditingController _searchController = TextEditingController();
  List<Prediction> _placesList = []; // Stores search results from Places API

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void _onSearchIconPressed() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
    });
  }

  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty) {
      setState(() {
        _placesList.clear();
      });
      return;
    }

    GoogleMapsPlaces places = GoogleMapsPlaces(apiKey: 'AIzaSyB-Auv39s_lM1kjpfOBySaQwxTMq5kfY-o');
    PlacesAutocompleteResponse response = await places.autocomplete(query);

    if (response.isOkay) {
      setState(() {
        _placesList = response.predictions;
      });
    } else {
      setState(() {
        _placesList.clear();
      });
    }
  }

  Future<void> _moveCameraToPlace(String placeId) async {
    GoogleMapsPlaces places = GoogleMapsPlaces(apiKey: 'AIzaSyB-Auv39s_lM1kjpfOBySaQwxTMq5kfY-o');
    PlacesDetailsResponse detail = await places.getDetailsByPlaceId(placeId);

    if (detail.isOkay) {
      final location = detail.result.geometry?.location;
      if (location != null) {
        mapController.animateCamera(CameraUpdate.newLatLngZoom(
          LatLng(location.lat, location.lng),
          15.0,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        toolbarHeight: _isSearchVisible ? 120 : 80,
        title: Column(
          children: [
            Align(
              alignment: Alignment.center,
              child: Container(
                width: 350,  // Die Breite der Suchleiste entspricht der Breite der App Bar
                height: 55,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                decoration: BoxDecoration(
                  color: const Color(0xCC717171),
                  borderRadius: BorderRadius.circular(35),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.search,
                          color: Colors.black, size: 40),
                      onPressed: _onSearchIconPressed,
                    ),
                    IconButton(
                      icon: const Icon(Icons.people,
                          color: Colors.black, size: 40),
                      onPressed: () {
                        Navigator.pushNamed(context, '/community');
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.account_circle,
                          color: Colors.black, size: 40),
                      onPressed: () {
                        // Action for account button
                      },
                    ),
                  ],
                ),
              ),
            ),
            if (_isSearchVisible)
              Container(
                width: 350,  // Die Breite der Suchergebnisbox entspricht der Breite der App Bar
                margin: const EdgeInsets.symmetric(vertical: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _searchPlaces,
                  decoration: InputDecoration(
                    hintText: 'Search for places...',
                    border: InputBorder.none,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _searchPlaces('');
                      },
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _center,
              zoom: 11.0,
            ),
          ),
          if (_isSearchVisible && _placesList.isNotEmpty)
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                width: 350,  // Die Breite der Suchergebnisbox entspricht der Breite der App Bar
                margin: const EdgeInsets.only(top: 190),
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(10),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _placesList.length,
                    itemBuilder: (context, index) {
                      final place = _placesList[index];
                      return ListTile(
                        title: Text(place.description!),
                        onTap: () {
                          _moveCameraToPlace(place.placeId!);
                          setState(() {
                            _placesList.clear();
                            _isSearchVisible = false;
                          });
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF717171),
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
                icon: const Icon(Icons.settings,
                    size: 40, color: Colors.black),
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
