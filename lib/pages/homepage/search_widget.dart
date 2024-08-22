import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';

class SearchWidget extends StatefulWidget {
  final bool isSearchVisible;
  final VoidCallback onSearchIconPressed;
  final GoogleMapController mapController;

  const SearchWidget({
    super.key,
    required this.isSearchVisible,
    required this.onSearchIconPressed,
    required this.mapController,
  });

  @override
  _SearchWidgetState createState() => _SearchWidgetState();
}

class _SearchWidgetState extends State<SearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  List<Prediction> _placesList = [];

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
        widget.mapController.animateCamera(CameraUpdate.newLatLng(
          LatLng(location.lat, location.lng),
        ));
        setState(() {
          _placesList.clear(); // Clear the search results after moving the camera
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.isSearchVisible)
          Container(
            height: 60, // Fixierte Höhe der Suchleiste
            margin: const EdgeInsets.only(top: 0), // Kein Abstand zur AppBar
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _searchPlaces,
                    decoration: const InputDecoration(
                      hintText: 'Search for courts...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _searchPlaces('');
                    widget.onSearchIconPressed(); // Schließen der Suchleiste, wenn sie geleert wird
                  },
                ),
              ],
            ),
          ),
        if (widget.isSearchVisible && _placesList.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 10), // Abstand unterhalb der Suchleiste
            padding: const EdgeInsets.symmetric(horizontal: 15),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.25, // Begrenze die Höhe der Liste auf maximal 30% der Bildschirmhöhe
            ),
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
                      _moveCameraToPlace(place.placeId!); // Bewege die Kamera zum ausgewählten Ort
                    },
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}
