import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';

class SearchWidget extends StatefulWidget {
  final bool isSearchVisible;
  final VoidCallback onSearchIconPressed;
  final GoogleMapController mapController;
  final Function(LatLng) onPlaceSelected; // Callback für ausgewählten Ort

  const SearchWidget({
    super.key,
    required this.isSearchVisible,
    required this.onSearchIconPressed,
    required this.mapController,
    required this.onPlaceSelected, // Neuer Parameter
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
        LatLng selectedLocation = LatLng(location.lat, location.lng);
        widget.mapController.animateCamera(CameraUpdate.newLatLng(selectedLocation));

        setState(() {
          _searchController.text = detail.result.name; // Display the selected place in the search bar
          _placesList.clear(); // Clear the search results after moving the camera
        });

        widget.onPlaceSelected(selectedLocation); // Trigger the callback to search for nearby sports places
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.isSearchVisible)
          Container(
            height: 50,
            margin: const EdgeInsets.only(top: 0),
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
                      contentPadding: EdgeInsets.symmetric(vertical: 15.0), // Center the text vertically
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _searchPlaces('');
                    widget.onSearchIconPressed(); // Close the search bar when cleared
                  },
                ),
              ],
            ),
          ),
        if (widget.isSearchVisible && _placesList.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 5),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.25,
            ),
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _placesList.length,
                itemBuilder: (context, index) {
                  final place = _placesList[index];
                  return ListTile(
                    title: Text(place.description!),
                    onTap: () {
                      _moveCameraToPlace(place.placeId!); // Move the camera to the selected place
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
