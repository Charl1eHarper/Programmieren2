import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapWidget extends StatefulWidget {
  final Function(GoogleMapController) onMapCreated; // Callback when the map is created
  final Set<Marker> markers; // Set of markers to be displayed on the map

  const MapWidget({super.key, required this.onMapCreated, required this.markers});

  @override
  _MapWidgetState createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  final LatLng _center = const LatLng(53.551086, 9.993682); // Default center position for the map (Hamburg)

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      onMapCreated: widget.onMapCreated, // Trigger the callback when the map is initialized
      initialCameraPosition: CameraPosition(
        target: _center, // Set the initial camera position on the map
        zoom: 11.0, // Initial zoom level
      ),
      markers: widget.markers, // Display the markers passed from the parent widget
    );
  }
}
