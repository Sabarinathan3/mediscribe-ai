import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/dio_client.dart';
import '../models/user_model.dart';

/// Centralized API service using the shared Dio client.
/// Provides typed methods for all backend endpoints.
final apiServiceProvider = Provider<ApiService>((ref) {
  final dio = ref.watch(dioClientProvider);
  return ApiService(dio);
});

class ApiService {
  final Dio _dio;

  ApiService(this._dio);

  // ==========================================
  // Auth Endpoints
  // ==========================================

  Future<Map<String, dynamic>> login(String phone, String password) async {
    final formData = FormData.fromMap({
      'username': phone,
      'password': password,
    });
    final response = await _dio.post('/auth/login', data: formData);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> register({
    required String fullName,
    required String phone,
    required String password,
    required String role,
  }) async {
    final response = await _dio.post('/auth/register', data: {
      'full_name': fullName,
      'phone': phone,
      'password': password,
      'locale': 'en',
      'role': role,
      'is_active': true,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<UserModel> getMe() async {
    final response = await _dio.get('/auth/me');
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  // ==========================================
  // Prescriptions
  // ==========================================

  Future<List<Map<String, dynamic>>> getPrescriptions() async {
    final response = await _dio.get('/prescriptions/');
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getPrescription(String id) async {
    final response = await _dio.get('/prescriptions/$id');
    return response.data as Map<String, dynamic>;
  }

  // ==========================================
  // AI / OCR
  // ==========================================

  Future<Map<String, dynamic>> processPrescription({
    required MultipartFile imageFile,
    String targetLang = 'en',
    bool generateAudio = false,
  }) async {
    final formData = FormData.fromMap({'file': imageFile});
    final response = await _dio.post(
      '/ai/process-prescription',
      data: formData,
      queryParameters: {
        'target_lang': targetLang,
        'generate_audio': generateAudio,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  // ==========================================
  // Reminders
  // ==========================================

  Future<List<Map<String, dynamic>>> getReminders() async {
    final response = await _dio.get('/reminders/');
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createReminder(Map<String, dynamic> data) async {
    final response = await _dio.post('/reminders/', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteReminder(String id) async {
    await _dio.delete('/reminders/$id');
  }

  // ==========================================
  // Medicine Schedules
  // ==========================================

  Future<List<Map<String, dynamic>>> getSchedules() async {
    final response = await _dio.get('/schedules/');
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createSchedule(Map<String, dynamic> data) async {
    final response = await _dio.post('/schedules/', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateSchedule(String id, Map<String, dynamic> data) async {
    final response = await _dio.put('/schedules/$id', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteSchedule(String id) async {
    await _dio.delete('/schedules/$id');
  }

  // ==========================================
  // Drug Interactions
  // ==========================================

  Future<List<Map<String, dynamic>>> checkInteractions(List<String> medicineIds) async {
    final response = await _dio.get(
      '/interactions/check',
      queryParameters: {'medicine_ids': medicineIds},
    );
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  // ==========================================
  // Medicines
  // ==========================================

  Future<List<Map<String, dynamic>>> searchMedicines(String query) async {
    final response = await _dio.get(
      '/medicines/',
      queryParameters: {'q': query},
    );
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  // ==========================================
  // Onboarding
  // ==========================================

  Future<List<Map<String, dynamic>>> getOnboardingSlides() async {
    final response = await _dio.get('/onboarding/slides');
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  // ==========================================
  // Prescriptions Extensions
  // ==========================================

  Future<void> deletePrescription(String id) async {
    await _dio.delete('/prescriptions/$id');
  }
}
