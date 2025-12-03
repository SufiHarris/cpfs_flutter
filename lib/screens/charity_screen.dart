import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:go_router/go_router.dart';
import '../core/models/charity_model.dart';
import '../widgets/app_scaffold.dart';

class CharityScreen extends StatefulWidget {
  const CharityScreen({super.key});

  @override
  State<CharityScreen> createState() => _CharityScreenState();
}

class _CharityScreenState extends State<CharityScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Charity> _charities = [];
  List<Charity> _filteredCharities = [];
  bool _isLoading = true;
  String? _error;
  String? _selectedCategory;

  final List<Map<String, dynamic>> _charityServices = [
    {
      'id': '1',
      'name': 'Financial',
      'description': 'Identify and request financial support',
      'icon': Icons.attach_money,
    },
    {
      'id': '2',
      'name': 'Clothing',
      'description': 'Identify and request available clothing support',
      'icon': Icons.checkroom,
    },
    {
      'id': '3',
      'name': 'Education',
      'description': 'Identify and request educational donations',
      'icon': Icons.school,
    },
    {
      'id': '4',
      'name': 'Counseling/Personal Services',
      'description': 'Identify and request counseling services',
      'icon': Icons.people,
    },
    {
      'id': '5',
      'name': 'Information Technology',
      'description': 'Identify and request IT services and products',
      'icon': Icons.computer,
    },
    {
      'id': '6',
      'name': 'Health Care/Food',
      'description': 'Identify and request health care and food services',
      'icon': Icons.medical_services,
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchCharities();
    _searchController.addListener(_filterCharities);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Build GraphQL query - always fetch all, filter client-side for now
  String _buildQuery() {
    return '''
      query ListCharitiesWithCategories {
        listCharitiesWithCategories(limit: 1000) {
          items {
            id
            name
            mission
            email
            phone
            website
            program
            programDescription
            processLink
            product
            category
          }
          nextToken
        }
      }
    ''';
  }

  Future<void> _fetchCharities({String? categoryFilter}) async {
    // Check if widget is still mounted before starting
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Build query
      final query = _buildQuery();

      safePrint('Executing query');

      // Create GraphQL request
      final request = GraphQLRequest<String>(
        document: query,
      );

      // Execute the query
      final response = await Amplify.API.query(request: request).response;

      safePrint('=== GraphQL Response Debug ===');
      safePrint('Response data: ${response.data}');
      safePrint('Response errors: ${response.errors}');

      // Check if widget is still mounted before updating state
      if (!mounted) return;

      // Check for GraphQL errors
      if (response.errors.isNotEmpty) {
        safePrint('GraphQL Errors found: ${response.errors}');
        setState(() {
          _error = 'Error: ${response.errors.first.message}';
          _isLoading = false;
        });
        return;
      }

      if (response.data == null) {
        setState(() {
          _error = 'No data received from server';
          _isLoading = false;
        });
        return;
      }

      // Parse the JSON response
      final Map<String, dynamic> data = json.decode(response.data!);

      safePrint('Parsed data structure: ${data.keys}');

      // Extract charities from response
      if (!data.containsKey('listCharitiesWithCategories')) {
        if (!mounted) return;
        setState(() {
          _error = 'Invalid response structure';
          _isLoading = false;
        });
        return;
      }

      final charitiesData = data['listCharitiesWithCategories'];

      if (charitiesData == null || !charitiesData.containsKey('items')) {
        if (!mounted) return;
        setState(() {
          _error = 'No items in response';
          _isLoading = false;
        });
        return;
      }

      final List<dynamic> items = charitiesData['items'] ?? [];

      safePrint('Number of charities fetched: ${items.length}');

      // Convert to Charity objects
      final List<Charity> fetchedCharities = items.map((item) {
        return Charity.fromJson(item as Map<String, dynamic>);
      }).toList();

      // Filter by category if one is selected
      List<Charity> displayCharities = fetchedCharities;
      if (categoryFilter != null && categoryFilter.isNotEmpty) {
        displayCharities = fetchedCharities.where((charity) {
          return charity.category?.toLowerCase() ==
              categoryFilter.toLowerCase();
        }).toList();
        safePrint(
            'Filtered to ${displayCharities.length} charities for category: $categoryFilter');
      }

      // Final mounted check before setState
      if (!mounted) return;

      setState(() {
        _charities = fetchedCharities; // Store all for search
        _filteredCharities = displayCharities; // Display filtered
        _isLoading = false;
        _error = null;
      });

      safePrint(
          'Successfully loaded ${_charities.length} charities, displaying ${_filteredCharities.length}');
    } catch (e, stackTrace) {
      safePrint('Error fetching charities: $e');
      safePrint('Stack trace: $stackTrace');

      // Check mounted before setState in catch block too
      if (!mounted) return;

      setState(() {
        _error = 'Failed to load charities. Please try again later.';
        _isLoading = false;
      });
    }
  }

  void _filterCharities() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      if (query.isEmpty) {
        _filteredCharities = _charities;
      } else {
        _filteredCharities = _charities.where((charity) {
          return charity.name.toLowerCase().contains(query) ||
              (charity.category?.toLowerCase().contains(query) ?? false) ||
              (charity.mission?.toLowerCase().contains(query) ?? false) ||
              (charity.program?.toLowerCase().contains(query) ?? false);
        }).toList();
      }
    });
  }

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
      _searchController.clear();
    });

    // Fetch charities filtered by category from AWS
    _fetchCharities(categoryFilter: category);
  }

  void _clearCategoryFilter() {
    setState(() {
      _selectedCategory = null;
      _searchController.clear();
    });

    // Fetch all charities
    _fetchCharities();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: RefreshIndicator(
        onRefresh: () => _fetchCharities(categoryFilter: _selectedCategory),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Categories Grid
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _charityServices.map((service) {
                  final isSelected = _selectedCategory == service['name'];
                  return SizedBox(
                    width: (MediaQuery.of(context).size.width - 48) / 3,
                    child: _buildServiceCard(service, isSelected),
                  );
                }).toList(),
              ),

              // Clear filter button
              if (_selectedCategory != null) ...[
                const SizedBox(height: 12),
                Center(
                  child: TextButton.icon(
                    onPressed: _clearCategoryFilter,
                    icon: const Icon(Icons.clear),
                    label: Text('Clear "$_selectedCategory" filter'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF13345C),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Search Bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search charities...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Charities List Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedCategory != null
                        ? '$_selectedCategory Charities'
                        : 'Available Charities',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF13345C),
                    ),
                  ),
                  if (!_isLoading && _filteredCharities.isNotEmpty)
                    Text(
                      '${_filteredCharities.length} found',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Loading, Error, or Charities List
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Column(
                      children: [
                        CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFF3498DB)),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Loading charities...',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_error != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _fetchCharities(
                              categoryFilter: _selectedCategory),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF13345C),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_filteredCharities.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.search_off,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _selectedCategory != null
                              ? 'No charities found in the "$_selectedCategory" category.'
                              : 'No charities found matching your search.',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                ..._filteredCharities.map((charity) {
                  return _buildCharityCard(charity);
                }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service, bool isSelected) {
    return InkWell(
      onTap: () => _selectCategory(service['name']),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3498DB) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
          border: isSelected
              ? Border.all(color: const Color(0xFF13345C), width: 2)
              : null,
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              service['icon'] as IconData,
              size: 24,
              color: isSelected ? Colors.white : const Color(0xFF3498DB),
            ),
            const SizedBox(height: 8),
            Text(
              service['name'],
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : const Color(0xFF13345C),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharityCard(Charity charity) {
    return InkWell(
      onTap: () {
        context.push('/protected/charity/details/${charity.id}');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    charity.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF13345C),
                    ),
                  ),
                ),
                if (charity.category != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE1F5FE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      charity.category!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF0277BD),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              charity.displayDescription,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF555555),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),

            // Footer
            Row(
              children: [
                const Icon(Icons.phone, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  charity.phone ?? 'No phone available',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
