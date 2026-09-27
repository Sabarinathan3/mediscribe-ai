import 'package:flutter_test/flutter_test.dart';
import 'package:mediscribe_app/models/user_model.dart';

void main() {
  group('UserModel Tests', () {
    test('fromJson should parse user model correctly', () {
      final json = {
        'id': 'uuid-1',
        'user_id': 'user-uuid-1',
        'full_name': 'John Doe',
        'phone': '+1234567890',
        'email': 'john.doe@example.com',
        'locale': 'es',
        'role': 'patient',
        'is_active': true,
      };

      final user = UserModel.fromJson(json);

      expect(user.id, 'uuid-1');
      expect(user.userId, 'user-uuid-1');
      expect(user.fullName, 'John Doe');
      expect(user.phone, '+1234567890');
      expect(user.email, 'john.doe@example.com');
      expect(user.locale, 'es');
      expect(user.role, 'patient');
      expect(user.isActive, true);
    });

    test('toJson should convert user model to json correctly', () {
      final user = UserModel(
        id: 'uuid-2',
        userId: 'user-uuid-2',
        fullName: 'Jane Doe',
        phone: '+0987654321',
        email: 'jane.doe@example.com',
        locale: 'fr',
        role: 'caregiver',
        isActive: false,
      );

      final json = user.toJson();

      expect(json['id'], 'uuid-2');
      expect(json['user_id'], 'user-uuid-2');
      expect(json['full_name'], 'Jane Doe');
      expect(json['phone'], '+0987654321');
      expect(json['email'], 'jane.doe@example.com');
      expect(json['locale'], 'fr');
      expect(json['role'], 'caregiver');
      expect(json['is_active'], false);
    });
  });
}
