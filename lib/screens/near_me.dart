import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import '../colors/color.dart';
import '../widgets/bottom_nav.dart';

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
  Marker? _userMarker;
  Set<Marker> _placeMarkers = {};
  String _selectedFilter = "pharmacy";
  
  LatLng? _currentPosition;


  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location services are disabled.')));
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are denied')));
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are permanently denied, we cannot request permissions.')));
      return;
    }

    // Permission granted, get current location and move camera
    _moveToCurrentLocation();
  }

  Future<void> _moveToCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best);
          
      final latLng = LatLng(position.latitude, position.longitude);
      _currentPosition = latLng;
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Got location: ${position.latitude}, ${position.longitude}")));
      
      if (_mapController != null) {
        _mapController!.animateCamera(CameraUpdate.newLatLngZoom(latLng, 14.0));
      }
      
      setState(() {
        _userMarker = Marker(
          markerId: const MarkerId('user_location'),
          position: latLng,
          infoWindow: const InfoWindow(title: 'Your Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          zIndex: 2, // ensure user pin stays on top
        );
      });
      _searchNearbyPlaces(_selectedFilter);
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  Future<void> _searchNearbyPlaces(String filter) async {
    if (_currentPosition == null) return;
    
    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY']; 
    if (apiKey == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Maps API Key missing! Check your .env file.")));
      return;
    }

    final baseUrl = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?"
        "location=${_currentPosition!.latitude},${_currentPosition!.longitude}"
        "&radius=5000"
        "&key=$apiKey";

    List<String> searchUrls = [];
    
    if (filter == "clinic") {
      searchUrls.add("$baseUrl&keyword=clinic");
      searchUrls.add("$baseUrl&keyword=klinik"); 
    } else if (filter == "pharmacy") {
      searchUrls.add("$baseUrl&type=pharmacy"); 
      searchUrls.add("$baseUrl&keyword=farmasi"); 
    } else {
      searchUrls.add("$baseUrl&type=$filter"); 
    }

    try {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Searching for $filter...")));
      }
      
      // Run all API requests simultaneously for maximum speed
      final responses = await Future.wait(
        searchUrls.map((url) => http.get(Uri.parse(url)))
      );
      
      Set<Marker> newMarkers = {};
      Set<String> seenPlaceIds = {}; // Keeps track of places so we don't add duplicates

      for (var response in responses) {
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final results = data['results'] as List;

          for (var place in results) {
            if (place['geometry'] == null || place['geometry']['location'] == null) continue;

            final placeId = place['place_id'];
            
            if (seenPlaceIds.contains(placeId)) continue;
            seenPlaceIds.add(placeId);

            final lat = place['geometry']['location']['lat'];
            final lng = place['geometry']['location']['lng'];
            final name = place['name'];
            final address = place['vicinity'] ?? ''; 
            
            // Determine color based on filter
            double hue = BitmapDescriptor.hueBlue;
            if (filter == "hospital") hue = BitmapDescriptor.hueRose;
            if (filter == "clinic") hue = BitmapDescriptor.hueGreen;
            if (filter == "pharmacy") hue = BitmapDescriptor.hueAzure;
            
            newMarkers.add(Marker(
              markerId: MarkerId(placeId),
              position: LatLng(lat, lng),
              infoWindow: InfoWindow(
                title: name,
                snippet: address, 
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(hue),
            ));
          }
        } else {
          print("API Error: ${response.statusCode}");
        }
      }

      setState(() {
        _placeMarkers = newMarkers;
      });
      
    } catch (e) {
      print("Error fetching places: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Widget _buildFilterChip(String label, String type, IconData icon) {
    final isSelected = _selectedFilter == type;
    return ActionChip(
      backgroundColor: isSelected ? AppColors.royalBlue : Colors.white,
      label: Row(
        children: [
          Icon(icon, size: 18, color: isSelected ? Colors.white : AppColors.royalBlue),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected ? AppColors.royalBlue : Colors.grey.shade300),
      ),
      onPressed: () {
        setState(() {
          _selectedFilter = type;
        });
        _searchNearbyPlaces(type);
      },
    );
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
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            mapType: MapType.normal,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
            markers: {
              if (_userMarker != null) _userMarker!,
              ..._placeMarkers,
            },
          ),

          Positioned(
            top: 60,
            left: 20,
            right: 20,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip("Pharmacy", "pharmacy", Icons.local_pharmacy),
                  const SizedBox(width: 8),
                  _buildFilterChip("Hospital", "hospital", Icons.local_hospital),
                  const SizedBox(width: 8),
                  _buildFilterChip("Clinic", "clinic", Icons.medical_services),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const MedicalBottomNav(),
    );
  }
}