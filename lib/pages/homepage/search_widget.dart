import 'package:flutter/material.dart';
import 'package:google_maps_webservice/places.dart';

class SearchWidget extends StatefulWidget {
  final bool isSearchVisible;
  final VoidCallback onSearchIconPressed;

  const SearchWidget({
    super.key,
    required this.isSearchVisible,
    required this.onSearchIconPressed,
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
        // Hier den MapController verwenden, um die Kamera zu bewegen
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.isSearchVisible)
          Container(
            height: 50, // Höhe der Suchleiste anpassen
            margin: const EdgeInsets.only(top: 0), // Abstand zur oberen AppBar
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
                    decoration: InputDecoration(
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
                    widget.onSearchIconPressed();  // Close search when cleared
                  },
                ),
              ],
            ),
          ),
        if (widget.isSearchVisible && _placesList.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 10), // Abstand zu der Suchleiste
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
                      });
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
