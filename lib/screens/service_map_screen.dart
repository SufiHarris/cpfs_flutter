import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/map_services.dart';
import '../widgets/app_scaffold.dart';

class MapsScreen extends StatefulWidget {
  const MapsScreen({super.key});

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  final Set<Marker> _markers = {};
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  Position? _currentPosition;
  MapLocation? _selectedLocation;
  bool _isLoadingLocation = false;
  bool _isLoadingData = true;
  String? _error;
  String _selectedFilter = 'all';

  List<MapLocation> _locations = [];

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(39.8283, -98.5795),
    zoom: 4,
  );

  final List<Map<String, dynamic>> _filterOptions = [
    {
      'key': 'all',
      'label': 'All Services',
      'icon': '🔍',
      'color': Color(0xFF95a5a6)
    },
    {
      'key': 'vso_office',
      'label': 'VSO Offices',
      'icon': '🏢',
      'color': Color(0xFF2ecc71)
    },
    {
      'key': 'cpfs_dropoff',
      'label': 'CPFS Drop-offs',
      'icon': '📱',
      'color': Color(0xFF3498db)
    },
    {
      'key': 'homeless_shelter',
      'label': 'Homeless Shelters',
      'icon': '🏠',
      'color': Color(0xFFe74c3c)
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoadingData = true;
      _error = null;
    });

    try {
      _locations = await MapsDataService.loadAllLocations();

      if (_locations.isEmpty) {
        throw Exception('No locations found in JSON files');
      }

      _loadMarkers();

      setState(() {
        _isLoadingData = false;
      });

      if (_locations.isNotEmpty) {
        _fitBoundsToMarkers();
      }
    } catch (e) {
      debugPrint('Error loading map data: $e');
      setState(() {
        _error =
            'Failed to load locations. Please check that JSON files are in assets/data/';
        _isLoadingData = false;
      });
    }
  }

  List<MapLocation> get _filteredLocations {
    if (_selectedFilter == 'all') {
      return _locations;
    }
    return _locations.where((loc) => loc.type == _selectedFilter).toList();
  }

  void _loadMarkers() {
    setState(() {
      _markers.clear();
      for (var location in _filteredLocations) {
        _markers.add(
          Marker(
            markerId: MarkerId(location.id),
            position: LatLng(location.latitude, location.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              _getMarkerColor(location.type),
            ),
            onTap: () {
              _showLocationModal(location);
            },
          ),
        );
      }
    });
  }

  void _showLocationModal(MapLocation location) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildLocationModal(location),
    );
  }

  Future<void> _fitBoundsToMarkers() async {
    if (_filteredLocations.isEmpty) return;

    final controller = await _controller.future;

    double minLat = _filteredLocations[0].latitude;
    double maxLat = _filteredLocations[0].latitude;
    double minLng = _filteredLocations[0].longitude;
    double maxLng = _filteredLocations[0].longitude;

    for (var location in _filteredLocations) {
      if (location.latitude < minLat) minLat = location.latitude;
      if (location.latitude > maxLat) maxLat = location.latitude;
      if (location.longitude < minLng) minLng = location.longitude;
      if (location.longitude > maxLng) maxLng = location.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    controller.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50),
    );
  }

  double _getMarkerColor(String? type) {
    switch (type) {
      case 'vso_office':
        return BitmapDescriptor.hueGreen;
      case 'cpfs_dropoff':
        return BitmapDescriptor.hueAzure;
      case 'homeless_shelter':
        return BitmapDescriptor.hueRed;
      case 'hospital':
        return BitmapDescriptor.hueRed;
      case 'clinic':
        return BitmapDescriptor.hueAzure;
      case 'support':
        return BitmapDescriptor.hueGreen;
      default:
        return BitmapDescriptor.hueRed;
    }
  }

  Color _getServiceTypeColor(String? type) {
    switch (type) {
      case 'vso_office':
        return const Color(0xFF2ecc71);
      case 'cpfs_dropoff':
        return const Color(0xFF3498db);
      case 'homeless_shelter':
        return const Color(0xFFe74c3c);
      case 'hospital':
        return const Color(0xFFe74c3c);
      case 'clinic':
        return const Color(0xFF3498db);
      case 'support':
        return const Color(0xFF2ecc71);
      default:
        return const Color(0xFF95a5a6);
    }
  }

  String _getServiceTypeIcon(String? type) {
    switch (type) {
      case 'vso_office':
        return '🏢';
      case 'cpfs_dropoff':
        return '📱';
      case 'homeless_shelter':
        return '🏠';
      case 'hospital':
        return '🏥';
      case 'clinic':
        return '🏢';
      case 'support':
        return '🤝';
      default:
        return '📍';
    }
  }

  String _getServiceTypeName(String? type) {
    switch (type) {
      case 'vso_office':
        return 'VSO Office';
      case 'cpfs_dropoff':
        return 'CPFS Drop-off Location';
      case 'homeless_shelter':
        return 'Homeless Shelter';
      case 'hospital':
        return 'VA Medical Center';
      case 'clinic':
        return 'VA Clinic';
      case 'support':
        return 'Vet Center';
      default:
        return 'Veteran Service';
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location permission denied'),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permissions are permanently denied'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isLoadingLocation = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;

      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
      });

      _markers
          .removeWhere((marker) => marker.markerId.value == 'user_location');

      setState(() {
        _markers.add(
          Marker(
            markerId: const MarkerId('user_location'),
            position: LatLng(position.latitude, position.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueBlue,
            ),
            infoWindow: const InfoWindow(
              title: 'Your Location',
            ),
          ),
        );
      });

      _zoomToLocation(position.latitude, position.longitude, zoom: 12);
    } catch (e) {
      debugPrint('Error getting location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to get your location'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _zoomToLocation(double lat, double lng,
      {double zoom = 14}) async {
    final controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(lat, lng),
          zoom: zoom,
        ),
      ),
    );
  }

  void _handleServiceLocationPress(MapLocation service) {
    setState(() {
      _selectedLocation = service;
    });
    _zoomToLocation(service.latitude, service.longitude, zoom: 14);

    // Collapse the sheet to show the map
    _sheetController.animateTo(
      0.3,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _openDirections(MapLocation location) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${location.latitude},${location.longitude}&travelmode=driving',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open directions'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final url = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not make phone call'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return const AppScaffold(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Loading map locations...',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return AppScaffold(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return AppScaffold(
      child: Stack(
        children: [
          // Full screen map
          Column(
            children: [
              // Header Section
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: const Column(
                  children: [
                    Text(
                      'Veteran Services & Support',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF13345C),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Find veteran services, support centers, and drop-off locations',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              // Map
              Expanded(
                child: GoogleMap(
                  mapType: MapType.normal,
                  initialCameraPosition: _initialPosition,
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  onMapCreated: (GoogleMapController controller) {
                    _controller.complete(controller);
                  },
                ),
              ),
            ],
          ),

          // My Location Button
          Positioned(
            top: 100,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              onPressed: _isLoadingLocation ? null : _getCurrentLocation,
              child: _isLoadingLocation
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location, color: Color(0xFF3498db)),
            ),
          ),

          // Draggable Bottom Sheet
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.4,
            minChildSize: 0.2,
            maxChildSize: 0.9,
            snap: true,
            snapSizes: const [0.2, 0.4, 0.9],
            builder: (BuildContext context, ScrollController scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Drag Handle
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),

                    // Filter Section (Sticky)
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          bottom: BorderSide(color: Color(0xFFEEEEEE)),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Filter Services',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF13345C),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 40,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _filterOptions.length,
                              itemBuilder: (context, index) {
                                final option = _filterOptions[index];
                                final isSelected =
                                    _selectedFilter == option['key'];
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: FilterChip(
                                    label: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          option['icon'],
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          option['label'],
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: isSelected
                                                ? Colors.white
                                                : option['color'],
                                          ),
                                        ),
                                      ],
                                    ),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      setState(() {
                                        _selectedFilter = option['key'];
                                        _loadMarkers();
                                        _fitBoundsToMarkers();
                                      });
                                    },
                                    backgroundColor: Colors.white,
                                    selectedColor: option['color'],
                                    side: BorderSide(
                                      color: option['color'],
                                      width: 1.5,
                                    ),
                                    showCheckmark: false,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Services List (Scrollable)
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(20),
                        children: [
                          Row(
                            children: [
                              Text(
                                'Service Locations (${_filteredLocations.length})',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF13345C),
                                ),
                              ),
                              if (_selectedFilter != 'all') ...[
                                const Text(
                                  ' • ',
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.grey),
                                ),
                                Text(
                                  _filterOptions.firstWhere(
                                    (f) => f['key'] == _selectedFilter,
                                  )['label'],
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Tap any location to zoom the map',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._filteredLocations
                              .map((service) => _buildServiceCard(service)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(MapLocation service) {
    return InkWell(
      onTap: () => _handleServiceLocationPress(service),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(
              color: _getServiceTypeColor(service.type),
              width: 4,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF13345C),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    service.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (service.address != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      service.address!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF888888),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (service.phone != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      service.phone!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF3498db),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.location_on,
              color: Color(0xFF3498db),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationModal(MapLocation location) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: _getServiceTypeColor(location.type),
                  width: 2,
                ),
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Text(
                  _getServiceTypeIcon(location.type),
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        location.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF13345C),
                        ),
                      ),
                      Text(
                        _getServiceTypeName(location.type),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getServiceTypeColor(location.type),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description
                Text(
                  location.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 12),

                // Address
                if (location.address != null) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('📍 ', style: TextStyle(fontSize: 16)),
                      Expanded(
                        child: Text(
                          location.address!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF444444),
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                // Phone
                if (location.phone != null) ...[
                  Row(
                    children: [
                      const Text('📞 ', style: TextStyle(fontSize: 16)),
                      Text(
                        location.phone!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF3498db),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                // Action Buttons
                Container(
                  padding: const EdgeInsets.only(top: 8),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Color(0xFFEEEEEE)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _openDirections(location);
                          },
                          icon: const Text('🧭'),
                          label: const Text('Directions'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3498db),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      if (location.phone != null) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _makePhoneCall(location.phone!);
                            },
                            icon: const Text('📞'),
                            label: const Text('Call'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2ecc71),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
