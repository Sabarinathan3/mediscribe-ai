import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_service.dart';

final prescriptionsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.getPrescriptions();
});
