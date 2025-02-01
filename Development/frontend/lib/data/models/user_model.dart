class User {
  final int id;
  final String username;
  final String email;
  final String? phone;
  final String? address;
  final String? licenseNo;
  final String? images;
  final String? role;
  final String? otp;
  final String? otpExpiry;
  final String? status;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.phone,
    this.address,
    this.licenseNo,
    this.images,
    this.role,
    this.otp,
    this.otpExpiry,
    this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0, // Defaults to 0 if null
      username: json['username'] ?? 'Unknown User', // Default username
      email: json['email'] ?? 'No Email',
      phone: json['phone'], // Allow null values
      address: json['address'],
      licenseNo: json['licenseNo'],
      images: json['images'],
      role: json['role'] ?? 'USER', // Default to USER
      otp: json['otp'],
      otpExpiry: json['otp_expiry'],
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}