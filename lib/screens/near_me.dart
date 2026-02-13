import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import '../colors/color.dart';
import '../widgets/bottom_nav.dart';
import '../backend/places_service.dart';

class NearMePage extends StatefulWidget {
  const NearMePage({super.key});

  @override
  State<NearMePage> createState() => _NearMePageState();
}

class _NearMePageState extends State<NearMePage> {
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(3.1209, 101.6538), 
    zoom: 15.0,
  );

  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final PlacesService _placesService = PlacesService();
  LatLng? _currentPosition;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initLocationService();
  }

  Future<void> _initLocationService() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      await _getCurrentLocation();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission required')),
        );
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      final latLng = LatLng(position.latitude, position.longitude);
      setState(() => _currentPosition = latLng);
      
      _mapController?.animateCamera(CameraUpdate.newLatLng(latLng));
      
      await _searchNearbyPlaces(latLng);
    } catch (e) {
      print("Error getting location: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _searchNearbyPlaces(LatLng center) async {
    final places = await _placesService.searchNearbyPlaces(
      latitude: center.latitude,
      longitude: center.longitude,
      type: 'pharmacy',
    );

    // Also fetch hospitals
    final hospitals = await _placesService.searchNearbyPlaces(
      latitude: center.latitude,
      longitude: center.longitude,
      type: 'hospital',
    );
    
    places.addAll(hospitals);

    setState(() {
      _markers.clear();
      for (var place in places) {
        final loc = place['geometry'];
        final lat = loc['lat'];
        final lng = loc['lng'];
        
        _markers.add(
          Marker(
            markerId: MarkerId(place['place_id']),
            position: LatLng(lat, lng),
            infoWindow: InfoWindow(
              title: place['name'],
              snippet: place['vicinity'],
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              place['html_attributions'] == [] ? BitmapDescriptor.hueRed : BitmapDescriptor.hueBlue, // Just a visual distinction attempt, though API doesn't give type easily in list
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialPosition,
            myLocationEnabled: true,
            zoomControlsEnabled: false,
            mapType: MapType.normal,
            markers: _markers,
            onMapCreated: (controller) {
              _mapController = controller;
              if (_currentPosition != null) {
                controller.animateCamera(CameraUpdate.newLatLng(_currentPosition!));
              }
            },
          ),

          if (_isLoading)
            const Center(child: CircularProgressIndicator()),

          Positioned(
            top: 60,
            left: 20,
            right: 20,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                      border: Border.all(color: AppColors.royalBlue),
                    ),
                    child: const TextField(
                      decoration: InputDecoration(
                        hintText: "Search pharmacies...",
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _getCurrentLocation,
                  child: Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                      border: Border.all(color: Colors.black12),
                    ),
                    child: const Icon(Icons.my_location, color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const MedicalBottomNav(),
    );
  }
}