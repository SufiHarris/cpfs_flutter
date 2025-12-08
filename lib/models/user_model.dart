// User Address Model
class UserAddress {
  final String? street;
  final String? city;
  final String? state;
  final String? zipCode;
  final String? country;

  UserAddress({
    this.street,
    this.city,
    this.state,
    this.zipCode,
    this.country,
  });

  factory UserAddress.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return UserAddress();
    }
    return UserAddress(
      street: json['street'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      zipCode: json['zipCode'] as String?,
      country: json['country'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'street': street ?? '',
      'city': city ?? '',
      'state': state ?? '',
      'zipCode': zipCode ?? '',
      'country': country ?? '',
    };
  }

  UserAddress copyWith({
    String? street,
    String? city,
    String? state,
    String? zipCode,
    String? country,
  }) {
    return UserAddress(
      street: street ?? this.street,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      country: country ?? this.country,
    );
  }
}

// In user_model.dart
class AppUserProfile {
  // Changed from UserProfile
  final String id;
  final String email;
  final String? militaryBranch;
  final String? age;
  final String? phoneNumber;
  final String? profilePicture;
  final UserAddress? address;

  AppUserProfile({
    required this.id,
    required this.email,
    this.militaryBranch,
    this.age,
    this.phoneNumber,
    this.profilePicture,
    this.address,
  });

  factory AppUserProfile.fromJson(Map<String, dynamic> json) {
    return AppUserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      militaryBranch: json['militaryBranch'] as String?,
      age: json['age'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      profilePicture: json['profilePicture'] as String?,
      address: UserAddress.fromJson(json['address'] as Map<String, dynamic>?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'militaryBranch': militaryBranch ?? '',
      'age': age ?? '',
      'phoneNumber': phoneNumber ?? '',
      'profilePicture': profilePicture,
      'address': address?.toJson() ??
          {
            'street': '',
            'city': '',
            'state': '',
            'zipCode': '',
            'country': '',
          },
    };
  }

  AppUserProfile copyWith({
    String? id,
    String? email,
    String? militaryBranch,
    String? age,
    String? phoneNumber,
    String? profilePicture,
    UserAddress? address,
  }) {
    return AppUserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      militaryBranch: militaryBranch ?? this.militaryBranch,
      age: age ?? this.age,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profilePicture: profilePicture ?? this.profilePicture,
      address: address ?? this.address,
    );
  }
}
