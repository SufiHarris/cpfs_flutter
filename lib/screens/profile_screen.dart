import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../widgets/app_scaffold.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  AuthUser? _authUser;
  AppUserProfile? _userProfile;
  bool _isLoading = true;
  bool _isImageLoading = false;
  String? _profileImageUrl;
  String? _error;

  final _militaryBranchController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipCodeController = TextEditingController();
  final _countryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _militaryBranchController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get authenticated user
      _authUser = await Amplify.Auth.getCurrentUser();
      final attributes = await Amplify.Auth.fetchUserAttributes();
      final email = attributes
          .firstWhere((attr) => attr.userAttributeKey.key == 'email')
          .value;

      safePrint('Loading profile for email: $email');

      // Fetch user from database
      final response = await Amplify.API
          .query(
            request: GraphQLRequest<String>(
              document: _listUsersQuery,
            ),
          )
          .response;

      if (!mounted) return;

      if (response.data != null) {
        final data = json.decode(response.data!);
        final items = data['listUsers']['items'] as List;

        // Filter by email client-side
        final userItems =
            items.where((item) => item['email'] == email).toList();

        if (userItems.isNotEmpty) {
          // User exists
          final userData = userItems.first;
          _userProfile = AppUserProfile.fromJson(userData);

          // Load profile image if exists
          if (_userProfile!.profilePicture != null) {
            await _loadProfileImage(_userProfile!.profilePicture!);
          }
        } else {
          // Create new user
          await _createNewUser(email);
        }
      }

      if (!mounted) return;
      setState(() => _isLoading = false);
    } catch (e) {
      safePrint('Error loading profile: $e');
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load profile';
        _isLoading = false;
      });
    }
  }

  Future<void> _createNewUser(String email) async {
    try {
      final response = await Amplify.API
          .mutate(
            request: GraphQLRequest<String>(
              document: _createUserMutation,
              variables: {
                'input': {
                  'email': email,
                  'militaryBranch': '',
                  'age': '',
                  'phoneNumber': '',
                  'profilePicture': null,
                  'address': {
                    'street': '',
                    'city': '',
                    'state': '',
                    'zipCode': '',
                    'country': '',
                  },
                },
              },
            ),
          )
          .response;

      if (response.data != null) {
        final data = json.decode(response.data!);
        _userProfile = AppUserProfile.fromJson(data['createUser']);
      }
    } catch (e) {
      safePrint('Error creating user: $e');
      // Use placeholder if creation fails
      _userProfile = AppUserProfile(
        id: '',
        email: email,
        militaryBranch: '',
        age: '',
        phoneNumber: '',
        address: UserAddress(
          street: '',
          city: '',
          state: '',
          zipCode: '',
          country: '',
        ),
      );
    }
  }

  Future<void> _loadProfileImage(String imageKey) async {
    try {
      // New Amplify Storage v2 API - getUrl with path
      final result = await Amplify.Storage.getUrl(
        path: StoragePath.fromString(imageKey),
      ).result;

      if (mounted) {
        setState(() {
          _profileImageUrl = result.url.toString();
        });
      }
    } catch (e) {
      safePrint('Error loading image: $e');
    }
  }

  Future<void> _pickAndUploadImage() async {
    if (_userProfile == null || _userProfile!.id.isEmpty) {
      _showSnackBar('Please wait for profile to load');
      return;
    }

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 70,
    );

    if (image == null) return;

    setState(() => _isImageLoading = true);

    try {
      // Generate unique key for private user storage
      final imageKey =
          'private/${_authUser!.userId}/profile-images/${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Upload to S3 using new API
      final file = File(image.path);

      await Amplify.Storage.uploadFile(
        localFile: AWSFile.fromPath(file.path),
        path: StoragePath.fromString(imageKey),
      ).result;

      safePrint('Image uploaded: $imageKey');

      // Update database using delete and recreate approach
      await _updateUserWithImage(imageKey);

      // Load new image
      await _loadProfileImage(imageKey);

      if (mounted) {
        _showSnackBar('Profile picture updated successfully');
      }
    } catch (e) {
      safePrint('Error uploading image: $e');
      if (mounted) {
        _showSnackBar('Failed to upload profile picture: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isImageLoading = false);
      }
    }
  }

  Future<void> _updateUserWithImage(String imageKey) async {
    try {
      // Delete existing user
      await Amplify.API
          .mutate(
            request: GraphQLRequest<String>(
              document: _deleteUserMutation,
              variables: {
                'input': {'id': _userProfile!.id},
              },
            ),
          )
          .response;

      // Recreate with new image
      final response = await Amplify.API
          .mutate(
            request: GraphQLRequest<String>(
              document: _createUserMutation,
              variables: {
                'input': {
                  'id': _userProfile!.id,
                  'email': _userProfile!.email,
                  'militaryBranch': _userProfile!.militaryBranch ?? '',
                  'age': _userProfile!.age ?? '',
                  'phoneNumber': _userProfile!.phoneNumber ?? '',
                  'profilePicture': imageKey,
                  'address': _userProfile!.address?.toJson() ??
                      {
                        'street': '',
                        'city': '',
                        'state': '',
                        'zipCode': '',
                        'country': '',
                      },
                },
              },
            ),
          )
          .response;

      if (response.data != null) {
        final data = json.decode(response.data!);
        setState(() {
          _userProfile = AppUserProfile.fromJson(data['createUser']);
        });
      }
    } catch (e) {
      safePrint('Error updating user with image: $e');
      // Update local state even if DB update fails
      setState(() {
        _userProfile = _userProfile!.copyWith(profilePicture: imageKey);
      });
    }
  }

  void _showEditDialog() {
    // Populate controllers with current values
    _militaryBranchController.text = _userProfile?.militaryBranch ?? '';
    _ageController.text = _userProfile?.age ?? '';
    _phoneController.text = _userProfile?.phoneNumber ?? '';
    _streetController.text = _userProfile?.address?.street ?? '';
    _cityController.text = _userProfile?.address?.city ?? '';
    _stateController.text = _userProfile?.address?.state ?? '';
    _zipCodeController.text = _userProfile?.address?.zipCode ?? '';
    _countryController.text = _userProfile?.address?.country ?? '';

    showDialog(
      context: context,
      builder: (context) => _buildEditDialog(),
    );
  }

  Widget _buildEditDialog() {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF13345C),
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.edit, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Edit Profile',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField(
                        'Military Branch', _militaryBranchController),
                    _buildTextField('Age', _ageController,
                        keyboardType: TextInputType.number),
                    _buildTextField('Phone Number', _phoneController,
                        keyboardType: TextInputType.phone),
                    const SizedBox(height: 16),
                    const Text(
                      'Address',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF13345C),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildTextField('Street', _streetController),
                    _buildTextField('City', _cityController),
                    _buildTextField('State', _stateController),
                    _buildTextField('Zip Code', _zipCodeController),
                    _buildTextField('Country', _countryController),
                  ],
                ),
              ),
            ),

            // Buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _saveProfile();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF13345C),
                      ),
                      child: const Text('Save',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.grey[50],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (_userProfile == null) return;

    try {
      // Delete existing user
      await Amplify.API
          .mutate(
            request: GraphQLRequest<String>(
              document: _deleteUserMutation,
              variables: {
                'input': {'id': _userProfile!.id},
              },
            ),
          )
          .response;

      // Recreate with updated data
      final response = await Amplify.API
          .mutate(
            request: GraphQLRequest<String>(
              document: _createUserMutation,
              variables: {
                'input': {
                  'id': _userProfile!.id,
                  'email': _userProfile!.email,
                  'militaryBranch': _militaryBranchController.text,
                  'age': _ageController.text,
                  'phoneNumber': _phoneController.text,
                  'profilePicture': _userProfile!.profilePicture,
                  'address': {
                    'street': _streetController.text,
                    'city': _cityController.text,
                    'state': _stateController.text,
                    'zipCode': _zipCodeController.text,
                    'country': _countryController.text,
                  },
                },
              },
            ),
          )
          .response;

      if (response.data != null) {
        final data = json.decode(response.data!);
        setState(() {
          _userProfile = AppUserProfile.fromJson(data['createUser']);
        });
        _showSnackBar('Profile updated successfully');
      }
    } catch (e) {
      safePrint('Error saving profile: $e');
      // Update local state if DB update fails
      setState(() {
        _userProfile = _userProfile!.copyWith(
          militaryBranch: _militaryBranchController.text,
          age: _ageController.text,
          phoneNumber: _phoneController.text,
          address: UserAddress(
            street: _streetController.text,
            city: _cityController.text,
            state: _stateController.text,
            zipCode: _zipCodeController.text,
            country: _countryController.text,
          ),
        );
      });
      _showSnackBar('Profile updated locally');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const AppScaffold(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading profile...'),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return AppScaffold(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error!),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadUserProfile,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return AppScaffold(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            const Text(
              'User Profile',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF13345C),
              ),
            ),
            const SizedBox(height: 24),

            // Profile Image
            GestureDetector(
              onTap: _isImageLoading ? null : _pickAndUploadImage,
              child: Column(
                children: [
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: const Color(0xFF2196F3), width: 3),
                    ),
                    child: _isImageLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _profileImageUrl != null
                            ? ClipOval(
                                child: Image.network(
                                  _profileImageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return _buildPlaceholderAvatar();
                                  },
                                ),
                              )
                            : _buildPlaceholderAvatar(),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to change photo',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Info Section
            _buildInfoCard([
              _buildInfoRow('Email', _userProfile?.email ?? 'N/A'),
              _buildInfoRow('Military Branch',
                  _userProfile?.militaryBranch ?? 'Not specified'),
              _buildInfoRow('Age', _userProfile?.age ?? 'Not specified'),
              _buildInfoRow(
                  'Phone Number', _userProfile?.phoneNumber ?? 'Not specified'),
            ]),

            // Address Section
            _buildInfoCard([
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'Address',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF13345C),
                  ),
                ),
              ),
              _buildInfoRow(
                  'Street', _userProfile?.address?.street ?? 'Not specified'),
              _buildInfoRow(
                  'City', _userProfile?.address?.city ?? 'Not specified'),
              _buildInfoRow(
                  'State', _userProfile?.address?.state ?? 'Not specified'),
              _buildInfoRow('Zip Code',
                  _userProfile?.address?.zipCode ?? 'Not specified'),
              _buildInfoRow(
                  'Country', _userProfile?.address?.country ?? 'Not specified'),
            ]),

            const SizedBox(height: 24),

            // Edit Button
            ElevatedButton.icon(
              onPressed: _showEditDialog,
              icon: const Icon(Icons.edit),
              label: const Text('Edit Profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderAvatar() {
    final initial = _userProfile?.email.isNotEmpty == true
        ? _userProfile!.email[0].toUpperCase()
        : '?';
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[300],
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            fontSize: 60,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF555555),
                fontSize: 16,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF333333),
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // GraphQL Queries
  static const String _listUsersQuery = '''
    query ListUsers {
      listUsers {
        items {
          id
          email
          militaryBranch
          age
          phoneNumber
          profilePicture
          address {
            street
            city
            state
            zipCode
            country
          }
        }
      }
    }
  ''';

  static const String _createUserMutation = '''
    mutation CreateUser(\$input: CreateUserInput!) {
      createUser(input: \$input) {
        id
        email
        militaryBranch
        age
        phoneNumber
        profilePicture
        address {
          street
          city
          state
          zipCode
          country
        }
      }
    }
  ''';

  static const String _deleteUserMutation = '''
    mutation DeleteUser(\$input: DeleteUserInput!) {
      deleteUser(input: \$input) {
        id
      }
    }
  ''';
}
