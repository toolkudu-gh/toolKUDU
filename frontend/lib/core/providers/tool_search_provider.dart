import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/tool_search_result.dart';
import '../services/tool_search_service.dart';
import 'location_provider.dart';

// Tool search service provider
final toolSearchServiceProvider = Provider<ToolSearchService>((ref) {
  return ToolSearchService();
});

// Tool search state
class ToolSearchState {
  final List<ToolSearchResult> results;
  final List<ToolCategory> categories;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String searchQuery;
  final String? selectedCategory;
  final String? error;
  final int currentOffset;

  const ToolSearchState({
    this.results = const [],
    this.categories = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.searchQuery = '',
    this.selectedCategory,
    this.error,
    this.currentOffset = 0,
  });

  ToolSearchState copyWith({
    List<ToolSearchResult>? results,
    List<ToolCategory>? categories,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? searchQuery,
    String? selectedCategory,
    String? error,
    int? currentOffset,
    bool clearCategory = false,
  }) {
    return ToolSearchState(
      results: results ?? this.results,
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      error: error,
      currentOffset: currentOffset ?? this.currentOffset,
    );
  }

  /// Get count of buddy tools in results
  int get buddyToolCount => results.where((t) => t.isBuddy).length;

  /// Get count of non-buddy tools in results
  int get otherToolCount => results.where((t) => !t.isBuddy).length;
}

// Tool search state notifier
class ToolSearchNotifier extends StateNotifier<ToolSearchState> {
  final ToolSearchService _searchService;
  final Ref _ref;

  static const int _pageSize = 20;

  ToolSearchNotifier(this._searchService, this._ref) : super(const ToolSearchState()) {
    _loadCategories();
  }

  /// Load available categories
  Future<void> _loadCategories() async {
    try {
      final categories = await _searchService.getCategories();
      state = state.copyWith(categories: categories);
    } catch (e) {
      // Ignore category loading errors
    }
  }

  /// Search for tools near the user's location
  Future<void> search({String? query, String? category, bool clearCategory = false}) async {
    final locationState = _ref.read(locationStateProvider);

    if (!locationState.location.hasLocation) {
      state = state.copyWith(
        error: 'Please set your location to search for nearby tools',
        isLoading: false,
      );
      return;
    }

    state = state.copyWith(
      isLoading: true,
      error: null,
      searchQuery: query ?? state.searchQuery,
      selectedCategory: clearCategory ? null : (category ?? state.selectedCategory),
      currentOffset: 0,
      hasMore: true,
    );

    try {
      final results = await _searchService.searchToolsNearby(
        latitude: locationState.location.latitude!,
        longitude: locationState.location.longitude!,
        query: state.searchQuery.isNotEmpty ? state.searchQuery : null,
        category: state.selectedCategory,
        limit: _pageSize,
        offset: 0,
      );

      state = state.copyWith(
        results: results,
        isLoading: false,
        hasMore: results.length >= _pageSize,
        currentOffset: results.length,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to search for tools',
      );
    }
  }

  /// Load more results (pagination)
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    final locationState = _ref.read(locationStateProvider);
    if (!locationState.location.hasLocation) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final moreResults = await _searchService.searchToolsNearby(
        latitude: locationState.location.latitude!,
        longitude: locationState.location.longitude!,
        query: state.searchQuery.isNotEmpty ? state.searchQuery : null,
        category: state.selectedCategory,
        limit: _pageSize,
        offset: state.currentOffset,
      );

      state = state.copyWith(
        results: [...state.results, ...moreResults],
        isLoadingMore: false,
        hasMore: moreResults.length >= _pageSize,
        currentOffset: state.currentOffset + moreResults.length,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  /// Update search query
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Set selected category filter
  void setCategory(String? category) {
    search(category: category, clearCategory: category == null);
  }

  /// Clear search and filters
  void clearSearch() {
    state = state.copyWith(
      searchQuery: '',
      selectedCategory: null,
      results: [],
      currentOffset: 0,
      hasMore: true,
      clearCategory: true,
    );
  }

  /// Refresh results
  Future<void> refresh() async {
    await search();
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Tool search state provider
final toolSearchStateProvider =
    StateNotifierProvider<ToolSearchNotifier, ToolSearchState>((ref) {
  final searchService = ref.watch(toolSearchServiceProvider);
  return ToolSearchNotifier(searchService, ref);
});

// Convenience providers
final toolSearchResultsProvider = Provider<List<ToolSearchResult>>((ref) {
  return ref.watch(toolSearchStateProvider).results;
});

final toolCategoriesProvider = Provider<List<ToolCategory>>((ref) {
  return ref.watch(toolSearchStateProvider).categories;
});

final isSearchingToolsProvider = Provider<bool>((ref) {
  return ref.watch(toolSearchStateProvider).isLoading;
});
