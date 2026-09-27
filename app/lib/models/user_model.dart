class UserModel {
  final String id;
  final String userId;
  final String fullName;
  final String? phone;
  final String? email;
  final String locale;
  final String role;
  final bool isActive;

  UserModel({
    required this.id,
    required this.userId,
    required this.fullName,
    this.phone,
    this.email,
    required this.locale,
    required this.role,
    required this.isActive,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      fullName: json['full_name'] as String? ?? '',
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      locale: json['locale'] as String? ?? 'en',
      role: json['role'] as String? ?? 'patient',
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'full_name': fullName,
      'phone': phone,
      'email': email,
      'locale': locale,
      'role': role,
      'is_active': isActive,
    };
  }

  UserModel copyWith({
    String? id,
    String? userId,
    String? fullName,
    String? phone,
    String? email,
    String? locale,
    String? role,
    bool? isActive,
  }) {
    return UserModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      locale: locale ?? this.locale,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
    );
  }
}
