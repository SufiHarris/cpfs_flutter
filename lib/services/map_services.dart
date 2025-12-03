import 'dart:convert';
import 'package:flutter/services.dart';

class MapLocation {
  final String id;
  final String title;
  final String description;
  final double latitude;
  final double longitude;
  final String? type;
  final String? address;
  final String? phone;

  MapLocation({
    required this.id,
    required this.title,
    required this.description,
    required this.latitude,
    required this.longitude,
    this.type,
    this.address,
    this.phone,
  });
}

class MapsDataService {
  /// Parse coordinates from string format "[lat,lng]" to [lat, lng] array
  static List<double>? parseCoordinates(dynamic coordinates) {
    try {
      if (coordinates == null) return null;

      // If it's already a List
      if (coordinates is List) {
        return [
          (coordinates[0] as num).toDouble(),
          (coordinates[1] as num).toDouble(),
        ];
      }

      // If it's a String like "[26.57694,-81.85394]"
      if (coordinates is String) {
        // Remove brackets and parse
        String cleaned =
            coordinates.replaceAll('[', '').replaceAll(']', '').trim();
        List<String> parts = cleaned.split(',');

        if (parts.length == 2) {
          double lat = double.parse(parts[0].trim());
          double lng = double.parse(parts[1].trim());
          return [lat, lng];
        }
      }

      return null;
    } catch (e) {
      print('Error parsing coordinates: $e');
      return null;
    }
  }

  /// Load all locations from JSON files
  static Future<List<MapLocation>> loadAllLocations() async {
    List<MapLocation> allLocations = [];

    try {
      // Load VSO Offices
      final vsoData =
          await rootBundle.loadString('assets/data/vso-offices.json');
      final vsoList = json.decode(vsoData) as List;

      for (var i = 0; i < vsoList.length; i++) {
        final office = vsoList[i];
        final coords = parseCoordinates(office['coordinates']);

        if (coords != null) {
          allLocations.add(MapLocation(
            id: 'vso_$i',
            title: '${office['county']} County VSO',
            description: 'Veterans Service Office - ${office['director']}',
            latitude: coords[0],
            longitude: coords[1],
            type: 'vso_office',
            address: office['address'],
            phone: office['workPhone'],
          ));
        }
      }

      // Load CPFS Drop-off Locations
      final cpfsData = await rootBundle
          .loadString('assets/data/cpfs-drop-off-locations.json');
      final cpfsList = json.decode(cpfsData) as List;

      for (var location in cpfsList) {
        final coords = parseCoordinates(location['coordinates']);

        if (coords != null) {
          allLocations.add(MapLocation(
            id: location['id'] ?? 'cpfs_${location['name']}',
            title: location['name'],
            description: 'Cell Phones For Soldiers Drop-off Location',
            latitude: coords[0],
            longitude: coords[1],
            type: 'cpfs_dropoff',
            address: '${location['address']}, ${location['cityStateZip']}',
            phone: location['phone'],
          ));
        }
      }

      // Load Homeless Shelters
      final sheltersData =
          await rootBundle.loadString('assets/data/homeless-shelters.json');
      final sheltersList = json.decode(sheltersData) as List;

      for (var i = 0; i < sheltersList.length; i++) {
        final shelter = sheltersList[i];
        final coords = parseCoordinates(shelter['coordinates']);

        if (coords != null) {
          allLocations.add(MapLocation(
            id: 'shelter_$i',
            title: shelter['name'],
            description: shelter['services'] ?? 'Homeless Shelter',
            latitude: coords[0],
            longitude: coords[1],
            type: 'homeless_shelter',
            address:
                '${shelter['address']}, ${shelter['city']}, ${shelter['state']} ${shelter['zipCode']}',
            phone: shelter['phone'],
          ));
        }
      }

      print('✅ Loaded ${allLocations.length} total locations');
      print(
          '   - VSO Offices: ${allLocations.where((l) => l.type == 'vso_office').length}');
      print(
          '   - CPFS Drop-offs: ${allLocations.where((l) => l.type == 'cpfs_dropoff').length}');
      print(
          '   - Homeless Shelters: ${allLocations.where((l) => l.type == 'homeless_shelter').length}');
    } catch (e) {
      print('❌ Error loading map data: $e');
      rethrow;
    }

    return allLocations;
  }
}
