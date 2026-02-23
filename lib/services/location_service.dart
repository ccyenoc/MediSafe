import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'firestore_service.dart';

class LocationService {
  final _firestoreService = FirestoreService();

  /// Quietly captures the device's GPS location and saves city/country to
  /// Firestore. Call this non-blocking from home_page initState.
  Future<void> captureAndSaveLocation() async {
    try {
      // Check if location service is on
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) { return; }

      // Check / request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) return;

      // Get position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );

      // Reverse geocode to get city / country name
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        await _firestoreService.updateLocation(
          city: place.locality ?? place.subAdministrativeArea ?? '',
          country: place.country ?? '',
          lat: position.latitude,
          lng: position.longitude,
        );
      }
    } catch (_) {
      // Location is optional — never crash the app if it fails
    }
  }
}
