import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

import '../models/charity_model.dart';
import '../core/shared/graphql_queries.dart';

class CharityDetailsScreen extends StatefulWidget {
  final String charityId;

  const CharityDetailsScreen({
    super.key,
    required this.charityId,
  });

  @override
  State<CharityDetailsScreen> createState() => _CharityDetailsScreenState();
}

class _CharityDetailsScreenState extends State<CharityDetailsScreen> {
  Charity? _charity;
  bool _isLoading = true;
  String? _error;
  bool _isBookmarked = false;
  String? _bookmarkId;
  bool _bookmarkLoading = false;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _fetchUserId();
    await _fetchCharityDetails();
    if (_charity != null && _userId != null) {
      await _checkBookmarkStatus();
    }
  }

  Future<void> _fetchUserId() async {
    try {
      final user = await Amplify.Auth.getCurrentUser();
      setState(() {
        _userId = user.userId;
      });
    } catch (e) {
      safePrint('Error fetching user ID: $e');
    }
  }

  Future<void> _fetchCharityDetails() async {
    try {
      // FIXED: Use String type instead of Map<String, dynamic>
      final request = GraphQLRequest<String>(
        document: GraphQLQueries.getCharitiesWithCategories,
        variables: {'id': widget.charityId},
      );

      final response = await Amplify.API.query(request: request).response;

      safePrint('Charity Details Response: ${response.data}');
      safePrint('Charity Details Errors: ${response.errors}');

      // Check for errors
      if (response.errors.isNotEmpty) {
        setState(() {
          _error = 'Error: ${response.errors.first.message}';
          _isLoading = false;
        });
        return;
      }

      if (response.data == null) {
        setState(() {
          _error = 'Failed to load charity details';
          _isLoading = false;
        });
        return;
      }

      // FIXED: Parse the JSON string response
      final data = json.decode(response.data!);
      final charityData = data['getCharitiesWithCategories'];

      if (charityData != null) {
        setState(() {
          _charity = Charity.fromJson(charityData as Map<String, dynamic>);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Charity not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      safePrint('Error fetching charity details: $e');
      setState(() {
        _error = 'Failed to load charity details';
        _isLoading = false;
      });
    }
  }

  Future<void> _checkBookmarkStatus() async {
    if (_userId == null || _charity == null) return;

    try {
      final request = GraphQLRequest<String>(
        document: GraphQLQueries.listBookmarks,
      );

      final response = await Amplify.API.query(request: request).response;

      if (response.data != null) {
        final data = json.decode(response.data!);
        final items = data['listBookmarks']['items'] as List;

        final userBookmark = items.firstWhere(
          (item) =>
              item['userId'] == _userId &&
              item['charityName'] == _charity!.name,
          orElse: () => null,
        );

        if (userBookmark != null) {
          setState(() {
            _isBookmarked = true;
            _bookmarkId = userBookmark['id'];
          });
        }
      }
    } catch (e) {
      safePrint('Error checking bookmark status: $e');
    }
  }

  Future<void> _toggleBookmark() async {
    if (_userId == null || _charity == null) {
      _showError('Unable to bookmark. Please try again later.');
      return;
    }

    setState(() => _bookmarkLoading = true);

    try {
      if (_isBookmarked && _bookmarkId != null) {
        // Delete bookmark
        final request = GraphQLRequest<String>(
          document: GraphQLQueries.deleteBookmark,
          variables: {
            'input': {'id': _bookmarkId},
          },
        );

        await Amplify.API.mutate(request: request).response;

        setState(() {
          _isBookmarked = false;
          _bookmarkId = null;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bookmark removed'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Create bookmark
        final request = GraphQLRequest<String>(
          document: GraphQLQueries.createBookmark,
          variables: {
            'input': {
              'userId': _userId!,
              'charityName': _charity!.name,
              'charityId': _charity!.id,
              'category': _charity!.category ?? 'General',
            },
          },
        );

        final response = await Amplify.API.mutate(request: request).response;

        if (response.data != null) {
          final data = json.decode(response.data!);
          final newBookmark = data['createBookmark'];

          setState(() {
            _isBookmarked = true;
            _bookmarkId = newBookmark['id'];
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Charity bookmarked!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      safePrint('Error toggling bookmark: $e');
      _showError('Failed to update bookmark. Please try again.');
    } finally {
      setState(() => _bookmarkLoading = false);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _launchUrl(String urlString) async {
    String url = urlString;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showError('Could not open link');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Charity Details'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading charity information...'),
            ],
          ),
        ),
      );
    }

    if (_error != null || _charity == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Charity Details'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  _error ?? 'Charity not found',
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Charity Details'),
        actions: [
          IconButton(
            icon: _bookmarkLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    _isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
                    color: _isBookmarked ? Colors.red : null,
                  ),
            onPressed: _bookmarkLoading ? null : _toggleBookmark,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and Category
            Text(
              _charity!.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF13345C),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE1F5FE),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _charity!.category ?? 'General',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF0277BD),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // About Section
            _buildSection(
              'About',
              _charity!.mission ??
                  _charity!.programDescription ??
                  'No description available.',
            ),

            // Program Section
            if (_charity!.program != null) ...[
              _buildSection(
                'Program',
                '${_charity!.program}\n${_charity!.programDescription ?? ''}',
              ),
            ],

            // Product Section
            if (_charity!.product != null && _charity!.product!.isNotEmpty) ...[
              _buildSection(
                'Products/Services',
                _charity!.product!,
              ),
            ],

            // Details Section
            _buildDetailsSection(),

            const SizedBox(height: 20),

            // Action Buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_charity!.website != null) {
                    _launchUrl(_charity!.website!);
                  } else if (_charity!.email != null) {
                    _launchUrl('mailto:${_charity!.email}');
                  } else {
                    _showError('No contact information available');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3498DB),
                  padding: const EdgeInsets.all(15),
                ),
                child: const Text(
                  'Support This Charity',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(15),
                ),
                child: const Text(
                  'Back to Charities',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF13345C),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Color(0xFF555555),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contact Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF13345C),
            ),
          ),
          const SizedBox(height: 10),
          if (_charity!.website != null)
            _buildDetailRow('Website:', _charity!.website, isLink: true),
          if (_charity!.email != null)
            _buildDetailRow('Email:', _charity!.email,
                isLink: true, isEmail: true),
          if (_charity!.phone != null)
            _buildDetailRow('Phone:', _charity!.phone),
          if (_charity!.processLink != null)
            _buildDetailRow('Process Link:', 'View Application Process',
                isLink: true, customUrl: _charity!.processLink),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value,
      {bool isLink = false, String? customUrl, bool isEmail = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF13345C),
              ),
            ),
          ),
          Expanded(
            child: isLink && value != null
                ? InkWell(
                    onTap: () {
                      if (isEmail) {
                        _launchUrl('mailto:$value');
                      } else {
                        _launchUrl(customUrl ?? value);
                      }
                    },
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF3498DB),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  )
                : Text(
                    value ?? 'N/A',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF555555),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
