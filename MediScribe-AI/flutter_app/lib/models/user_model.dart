class UserModel {
  final String id;
  final String userId;
  final String fullName;
  final String? phone;
  final String locale;
  final String role;
  final bool isActive;

  UserModel({
    required this.id,
    required this.userId,
    required this.fullName,
    this.phone,
    required this.locale,
    required this.role,
    required this.isActive,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String?,
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
    String? locale,
    String? role,
    bool? isActive,
  }) {
    return UserModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      locale: locale ?? this.locale,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
    );
  }
}
