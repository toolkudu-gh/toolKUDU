import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../models/tool_search_result.dart';

/// Service for searching tools by location
class ToolSearchService {
  final Dio _api;

  ToolSearchService()
      : _api = Dio(BaseOptions(
          baseUrl: AppConfig.apiBaseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ));

  /// Set the auth token for API requests
  void setAuthToken(String? token) {
    if (token != null) {
      _api.options.headers['Authorization'] = 'Bearer $token';
    } else {
      _api.options.headers.remove('Authorization');
    }
  }

  /// Search for tools near a location
  /// Returns tools within the specified radius, sorted by buddy status then distance
  Future<List<ToolSearchResult>> searchToolsNearby({
    required double latitude,
    required double longitude,
    int radiusMiles = 100,
    String? query,
    String? category,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _api.get('/api/tools/search', queryParameters: {
        'latitude': latitude,
        'longitude': longitude,
        'radius': radiusMiles,
        if (query != null && query.isNotEmpty) 'q': query,
        if (category != null && category.isNotEmpty) 'category': category,
        'limit': limit,
        'offset': offset,
      });

      if (response.statusCode == 200) {
        final items = response.data['items'] as List? ?? [];
        return items
            .map((e) => ToolSearchResult.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('Tool search failed: $e');
      return [];
    }
  }

  /// Get available tool categories with counts
  Future<List<ToolCategory>> getCategories() async {
    try {
      final response = await _api.get('/api/tools/categories');

      if (response.statusCode == 200) {
        final items = response.data['items'] as List? ?? response.data as List? ?? [];
        return items
            .map((e) => ToolCategory.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return _defaultCategories;
    } catch (e) {
      // Return default categories without counts on error
      return _defaultCategories;
    }
  }

  /// Default categories (shown when API unavailable, counts will be 0)
  static const List<ToolCategory> _defaultCategories = [
    ToolCategory(id: 'power_tools', name: 'Power Tools', toolCount: 0),
    ToolCategory(id: 'hand_tools', name: 'Hand Tools', toolCount: 0),
    ToolCategory(id: 'garden', name: 'Garden & Outdoor', toolCount: 0),
    ToolCategory(id: 'automotive', name: 'Automotive', toolCount: 0),
    ToolCategory(id: 'woodworking', name: 'Woodworking', toolCount: 0),
    ToolCategory(id: 'electrical', name: 'Electrical', toolCount: 0),
    ToolCategory(id: 'plumbing', name: 'Plumbing', toolCount: 0),
    ToolCategory(id: 'painting', name: 'Painting', toolCount: 0),
  ];
}
