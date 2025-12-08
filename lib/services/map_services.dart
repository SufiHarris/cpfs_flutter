import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../core/shared/graphql_queries.dart';

/// Model for map locations
class MapLocation {
  final String id;
  final double latitude;
  final double longitude;
  final String title;
  final String description;
  final String? address;
  final String? phone;
  final String? email;
  final String? website;
  final String? type;

  // CPFS-specific
  final String? cityStateZip;

  // Shelter-specific
  final String? services;
  final String? city;
  final String? state;
  final String? zipCode;

  // VSO-specific
  final String? county;
  final String? director;
  final String? workPhone;
  final String? fax;

  MapLocation({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.title,
    required this.description,
    this.address,
    this.phone,
    this.email,
    this.website,
    this.type,
    this.cityStateZip,
    this.services,
    this.city,
    this.state,
    this.zipCode,
    this.county,
    this.director,
    this.workPhone,
    this.fax,
  });

  /// Parse coordinates from either array format or string format
  static List<double> _parseCoordinates(dynamic coordinatesData) {
    if (coordinatesData is List) {
      // Handle array format: [44.46496, -73.17934]
      return [
        (coordinatesData[0] as num).toDouble(),
        (coordinatesData[1] as num).toDouble(),
      ];
    } else if (coordinatesData is String) {
      // Handle string format: "[26.57694,-81.85394]"
      final cleaned = coordinatesData.replaceAll('[', '').replaceAll(']', '');
      final parts = cleaned.split(',');
      return [
        double.parse(parts[0].trim()),
        double.parse(parts[1].trim()),
      ];
    }
    throw Exception('Invalid coordinates format: $coordinatesData');
  }

  /// Parse from AWS GraphQL response
  factory MapLocation.fromJson(Map<String, dynamic> json) {
    double lat;
    double lng;

    // Check if coordinates field exists
    if (json.containsKey('coordinates') && json['coordinates'] != null) {
      final coords = _parseCoordinates(json['coordinates']);
      lat = coords[0];
      lng = coords[1];
    } else {
      // Fallback to separate latitude/longitude fields
      lat = (json['latitude'] as num).toDouble();
      lng = (json['longitude'] as num).toDouble();
    }

    return MapLocation(
      id: json['id'] as String,
      latitude: lat,
      longitude: lng,
      title: json['name'] as String,
      description: json['description'] as String? ?? '',
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      website: json['website'] as String?,
      type: json['type'] as String?,
      cityStateZip: json['cityStateZip'] as String?,
      services: json['services'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      zipCode: json['zipCode'] as String?,
      county: json['county'] as String?,
      director: json['director'] as String?,
      workPhone: json['workPhone'] as String?,
      fax: json['fax'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'name': title,
      'description': description,
      'address': address,
      'phone': phone,
      'email': email,
      'website': website,
      'type': type,
      'cityStateZip': cityStateZip,
      'services': services,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'county': county,
      'director': director,
      'workPhone': workPhone,
      'fax': fax,
    };
  }
}

class MapsDataService {
  /// Load all locations from AWS using Amplify Model queries
  static Future<List<MapLocation>> loadAllLocations() async {
    try {
      safePrint('🔍 Starting to load locations from AWS...');

      final locations = <MapLocation>[];
      String? nextToken;
      int pageCount = 0;

      // Fetch all pages
      do {
        pageCount++;
        safePrint('📄 Fetching page $pageCount...');

        final request = GraphQLRequest<String>(
          document: GraphQLQueries.listLocations,
          variables: {
            'limit': 1000,
            if (nextToken != null) 'nextToken': nextToken,
          },
        );

        final response = await Amplify.API.query(request: request).response;

        if (response.errors.isNotEmpty) {
          safePrint('❌ GraphQL Errors: ${response.errors}');
          throw Exception('GraphQL Error: ${response.errors.first.message}');
        }

        if (response.data == null) {
          throw Exception('No data received from AWS');
        }

        final data = json.decode(response.data!);
        final listLocationsData = data['listLocations'];

        if (listLocationsData == null) {
          throw Exception('listLocations is null in response');
        }

        final items = listLocationsData['items'] as List?;
        nextToken = listLocationsData['nextToken'] as String?;

        if (items != null) {
          final pageLocations = items
              .map((item) => MapLocation.fromJson(item as Map<String, dynamic>))
              .toList();

          locations.addAll(pageLocations);
          safePrint(
              '✅ Page $pageCount: Loaded ${pageLocations.length} locations (total: ${locations.length})');
        }
      } while (nextToken != null);

      safePrint(
          '🎉 Successfully loaded ${locations.length} total locations from AWS');

      // Print breakdown by type
      final typeCounts = <String, int>{};
      for (var loc in locations) {
        typeCounts[loc.type ?? 'unknown'] =
            (typeCounts[loc.type ?? 'unknown'] ?? 0) + 1;
      }
      safePrint('📊 Locations by type:');
      typeCounts.forEach((type, count) {
        safePrint('   - $type: $count');
      });

      return locations;
    } catch (e, stackTrace) {
      safePrint('❌ Error loading locations from AWS: $e');
      safePrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Load locations by specific type
  static Future<List<MapLocation>> loadLocationsByType(String type) async {
    try {
      safePrint('🔍 Loading locations of type: $type');

      final request = GraphQLRequest<String>(
        document: GraphQLQueries.locationsByType,
        variables: {
          'type': type,
          'limit': 1000,
        },
      );

      final response = await Amplify.API.query(request: request).response;

      if (response.errors.isNotEmpty) {
        throw Exception('GraphQL Error: ${response.errors.first.message}');
      }

      if (response.data == null) {
        throw Exception('No data received');
      }

      final data = json.decode(response.data!);
      final items = data['locationsByType']['items'] as List;

      final locations = items
          .map((item) => MapLocation.fromJson(item as Map<String, dynamic>))
          .toList();

      safePrint('✅ Loaded ${locations.length} locations of type: $type');
      return locations;
    } catch (e) {
      safePrint('❌ Error loading locations by type: $e');
      rethrow;
    }
  }

  /// Load CPFS drop-off locations
  static Future<List<MapLocation>> loadCpfsLocations() async {
    return loadLocationsByType('cpfs_dropoff');
  }

  /// Load homeless shelters
  static Future<List<MapLocation>> loadHomelessShelters() async {
    return loadLocationsByType('homeless_shelter');
  }

  /// Load VSO offices
  static Future<List<MapLocation>> loadVsoOffices() async {
    return loadLocationsByType('vso_office');
  }

  /// Filter locations by type from already loaded data
  static List<MapLocation> filterByType(
      List<MapLocation> locations, String type) {
    return locations.where((location) => location.type == type).toList();
  }

  /// Get locations grouped by type
  static Map<String, List<MapLocation>> groupByType(
      List<MapLocation> locations) {
    final Map<String, List<MapLocation>> grouped = {};

    for (var location in locations) {
      final type = location.type ?? 'unknown';
      if (!grouped.containsKey(type)) {
        grouped[type] = [];
      }
      grouped[type]!.add(location);
    }

    return grouped;
  }

  /// Get unique location types
  static List<String> getLocationTypes(List<MapLocation> locations) {
    return locations
        .map((location) => location.type ?? 'unknown')
        .toSet()
        .toList()
      ..sort();
  }

  /// Search locations by name, address, or description
  static List<MapLocation> searchLocations(
      List<MapLocation> locations, String query) {
    final lowerQuery = query.toLowerCase();
    return locations.where((location) {
      return location.title.toLowerCase().contains(lowerQuery) ||
          (location.address?.toLowerCase().contains(lowerQuery) ?? false) ||
          location.description.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Get location count by type
  static Map<String, int> getLocationCountByType(List<MapLocation> locations) {
    final counts = <String, int>{};
    for (var location in locations) {
      final type = location.type ?? 'unknown';
      counts[type] = (counts[type] ?? 0) + 1;
    }
    return counts;
  }
}
