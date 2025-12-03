import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:go_router/go_router.dart';
import '../models/charity_model.dart';
import '../core/shared/graphql_queries.dart';
import '../widgets/app_scaffold.dart';
import 'dart:convert';

class SavedBookmarksScreen extends StatefulWidget {
  const SavedBookmarksScreen({super.key});

  @override
  State<SavedBookmarksScreen> createState() => _SavedBookmarksScreenState();
}

class _SavedBookmarksScreenState extends State<SavedBookmarksScreen> {
  List<Bookmark> _bookmarks = [];
  bool _isLoading = true;
  String? _error;
  String? _userId;
  bool _isRefreshing = false;
  String? _deleteInProgress;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _fetchUserId();
    if (_userId != null) {
      await _fetchBookmarks();
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
      setState(() {
        _error = 'Failed to authenticate user';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchBookmarks() async {
    if (_userId == null) return;

    setState(() {
      if (!_isRefreshing) {
        _isLoading = true;
      }
      _error = null;
    });

    try {
      final request = GraphQLRequest<String>(
        document: GraphQLQueries.listBookmarks,
      );

      final response = await Amplify.API.query(request: request).response;

      if (response.data != null) {
        final data = json.decode(response.data!);
        final items = data['listBookmarks']['items'] as List;

        // Filter bookmarks by current user
        final userBookmarks = items
            .where((item) => item['userId'] == _userId)
            .map((item) => Bookmark.fromJson(item))
            .toList();

        // Sort by creation date (newest first)
        userBookmarks.sort((a, b) {
          if (a.createdAt == null || b.createdAt == null) return 0;
          return b.createdAt!.compareTo(a.createdAt!);
        });

        setState(() {
          _bookmarks = userBookmarks;
          _isLoading = false;
          _isRefreshing = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load saved charities';
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      safePrint('Error fetching bookmarks: $e');
      setState(() {
        _error = 'Failed to load saved charities';
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    await _fetchBookmarks();
  }

  Future<void> _removeBookmark(Bookmark bookmark) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Saved Charity'),
        content: Text(
          'Are you sure you want to remove "${bookmark.charityName}" from your saved charities?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _deleteInProgress = bookmark.id);

    try {
      final request = GraphQLRequest<String>(
        document: GraphQLQueries.deleteBookmark,
        variables: {
          'input': {'id': bookmark.id},
        },
      );

      await Amplify.API.mutate(request: request).response;

      setState(() {
        _bookmarks.removeWhere((b) => b.id == bookmark.id);
        _deleteInProgress = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Charity removed from saved list'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      safePrint('Error removing bookmark: $e');
      setState(() => _deleteInProgress = null);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Failed to remove saved charity: ${e.toString()}. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToCharityDetails(Bookmark bookmark) {
    final identifier = bookmark.charityId ?? bookmark.charityName;
    context.push('/protected/charity/details/$identifier');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && !_isRefreshing) {
      return const AppScaffold(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Loading saved charities...',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return AppScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'My Saved Charities',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF13345C),
              ),
            ),
          ),
          Expanded(
            child: _error != null
                ? _buildErrorView()
                : _bookmarks.isEmpty
                    ? _buildEmptyView()
                    : _buildBookmarksList(),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _error!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _fetchBookmarks,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3498DB),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.bookmark_outline,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'No saved charities yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF13345C),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bookmark charities you\'re interested in to find them here',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/protected/charity'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3498DB),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text(
                'Browse Charities',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookmarksList() {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _bookmarks.length,
        itemBuilder: (context, index) {
          final bookmark = _bookmarks[index];
          final isDeleting = _deleteInProgress == bookmark.id;

          return InkWell(
            onTap:
                isDeleting ? null : () => _navigateToCharityDetails(bookmark),
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
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bookmark.charityName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF13345C),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE1F5FE),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            bookmark.category ?? 'General',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF0277BD),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: isDeleting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.close,
                            color: Color(0xFFD23631),
                          ),
                    onPressed:
                        isDeleting ? null : () => _removeBookmark(bookmark),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
