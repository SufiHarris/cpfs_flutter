class Charity {
  final String id;
  final String name;
  final String? mission;
  final String? email;
  final String? phone;
  final String? website;
  final String? program;
  final String? programDescription;
  final String? processLink;
  final String? product;
  final String? category;

  Charity({
    required this.id,
    required this.name,
    this.mission,
    this.email,
    this.phone,
    this.website,
    this.program,
    this.programDescription,
    this.processLink,
    this.product,
    this.category,
  });

  factory Charity.fromJson(Map<String, dynamic> json) {
    return Charity(
      id: json['id'] as String,
      name: json['name'] as String,
      mission: json['mission'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      website: json['website'] as String?,
      program: json['program'] as String?,
      programDescription: json['programDescription'] as String?,
      processLink: json['processLink'] as String?,
      product: json['product'] as String?,
      category: json['category'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'mission': mission,
      'email': email,
      'phone': phone,
      'website': website,
      'program': program,
      'programDescription': programDescription,
      'processLink': processLink,
      'product': product,
      'category': category,
    };
  }

  String get displayDescription {
    return mission ?? programDescription ?? 'No description available.';
  }
}

// Bookmark Model
class Bookmark {
  final String id;
  final String userId;
  final String charityName;
  final String? charityId;
  final String? category;
  final DateTime? createdAt;

  Bookmark({
    required this.id,
    required this.userId,
    required this.charityName,
    this.charityId,
    this.category,
    this.createdAt,
  });

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      id: json['id'] as String,
      userId: json['userId'] as String,
      charityName: json['charityName'] as String,
      charityId: json['charityId'] as String?,
      category: json['category'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'charityName': charityName,
      'charityId': charityId,
      'category': category,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
