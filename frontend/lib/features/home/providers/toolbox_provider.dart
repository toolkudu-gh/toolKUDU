import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/toolbox.dart';
import '../../../core/models/tool.dart';
import '../../../core/services/api_service.dart';
import '../../../core/providers/auth_provider.dart';

// Toolboxes list provider - fetches from API
final toolboxesProvider = FutureProvider<List<Toolbox>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final currentUser = ref.watch(currentUserProvider);

  // If not authenticated, return empty list
  if (currentUser == null) {
    return [];
  }

  try {
    final response = await api.get('/api/users/${currentUser.id}/toolboxes');

    // Handle paginated response
    final items = response['items'] as List? ?? response['data'] as List? ?? [];
    return items.map((e) => Toolbox.fromJson(e as Map<String, dynamic>)).toList();
  } catch (e) {
    print('Failed to fetch toolboxes: $e');
    // Return empty list on error - could also rethrow to show error state
    return [];
  }
});

// Single toolbox provider
final toolboxProvider = FutureProvider.family<Toolbox?, String>((ref, id) async {
  final api = ref.watch(apiServiceProvider);

  try {
    final response = await api.get('/api/toolboxes/$id');
    return Toolbox.fromJson(response);
  } catch (e) {
    print('Failed to fetch toolbox $id: $e');
    return null;
  }
});

// Tools in a toolbox provider
final toolsInToolboxProvider = FutureProvider.family<List<Tool>, String>((ref, toolboxId) async {
  final api = ref.watch(apiServiceProvider);

  try {
    final response = await api.get('/api/toolboxes/$toolboxId/tools');

    // Handle paginated response
    final items = response['items'] as List? ?? response['data'] as List? ?? [];
    return items.map((e) => Tool.fromJson(e as Map<String, dynamic>)).toList();
  } catch (e) {
    print('Failed to fetch tools for toolbox $toolboxId: $e');
    return [];
  }
});

// Single tool provider
final toolProvider = FutureProvider.family<Tool?, String>((ref, id) async {
  final api = ref.watch(apiServiceProvider);

  try {
    final response = await api.get('/api/tools/$id');
    return Tool.fromJson(response);
  } catch (e) {
    print('Failed to fetch tool $id: $e');
    return null;
  }
});
