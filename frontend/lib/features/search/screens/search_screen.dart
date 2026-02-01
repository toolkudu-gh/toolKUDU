import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_input.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/location_permission_dialog.dart';
import '../../../core/providers/location_provider.dart';
import '../../../core/providers/tool_search_provider.dart';
import '../../../core/utils/funny_messages.dart';
import '../widgets/tool_search_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  final bool borrowMode;

  const SearchScreen({super.key, this.borrowMode = false});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Load initial results if location is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final hasLocation = ref.read(hasLocationProvider);
      if (hasLocation) {
        ref.read(toolSearchStateProvider.notifier).search();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(toolSearchStateProvider.notifier).loadMore();
    }
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    ref.read(toolSearchStateProvider.notifier).search(query: query);
  }

  Future<void> _showLocationDialog() async {
    await LocationPermissionDialog.show(context);
    if (mounted) {
      final hasLocation = ref.read(hasLocationProvider);
      if (hasLocation) {
        ref.read(toolSearchStateProvider.notifier).search();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locationState = ref.watch(locationStateProvider);
    final searchState = ref.watch(toolSearchStateProvider);
    final hasLocation = locationState.location.hasLocation;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Find Tools',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppTheme.textPrimaryDark
                            : AppTheme.textPrimaryLight,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),

            // Location indicator
            if (hasLocation)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: LocationIndicator(
                  zipcode: locationState.location.zipcode,
                  onTap: _showLocationDialog,
                ),
              ).animate().fadeIn(delay: 50.ms, duration: 300.ms),

            // Search input
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: AppSearchInput(
                controller: _searchController,
                hint: 'Search tools, brands, categories...',
                onChanged: (value) {
                  if (value.isEmpty) {
                    _performSearch();
                  }
                },
                onSubmitted: (_) => _performSearch(),
                onClear: () {
                  ref.read(toolSearchStateProvider.notifier).clearSearch();
                  ref.read(toolSearchStateProvider.notifier).search();
                },
              ),
            ).animate().fadeIn(delay: 100.ms, duration: 300.ms),

            // Category filters
            if (hasLocation && searchState.categories.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: searchState.categories.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        // "All" chip
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: CategoryChip(
                            label: 'All',
                            isSelected: searchState.selectedCategory == null,
                            onTap: () {
                              ref.read(toolSearchStateProvider.notifier).setCategory(null);
                            },
                          ),
                        );
                      }
                      final category = searchState.categories[index - 1];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: CategoryChip(
                          label: category.name,
                          isSelected: searchState.selectedCategory == category.id,
                          onTap: () {
                            ref.read(toolSearchStateProvider.notifier).setCategory(category.id);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ).animate().fadeIn(delay: 150.ms, duration: 300.ms),

            const SizedBox(height: 16),

            // Content
            Expanded(
              child: _buildContent(context, isDark, hasLocation, searchState),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    bool isDark,
    bool hasLocation,
    ToolSearchState searchState,
  ) {
    // No location set
    if (!hasLocation) {
      return _buildNoLocationState(context, isDark);
    }

    // Loading
    if (searchState.isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 5,
        itemBuilder: (context, index) => const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: CardSkeleton(height: 120, showImage: true),
        ),
      );
    }

    // Error
    if (searchState.error != null) {
      return EmptyState.error(
        title: 'Something went wrong',
        description: searchState.error,
        actionLabel: 'Try Again',
        onAction: () => ref.read(toolSearchStateProvider.notifier).refresh(),
      );
    }

    // No results
    if (searchState.results.isEmpty) {
      return EmptyState(
        icon: Icons.handyman_outlined,
        title: 'No tools found',
        description: searchState.searchQuery.isNotEmpty
            ? 'Try a different search term'
            : FunnyMessages.noNearbyTools,
        compact: true,
      ).animate().fadeIn(duration: 300.ms);
    }

    // Results
    return RefreshIndicator(
      onRefresh: () => ref.read(toolSearchStateProvider.notifier).refresh(),
      color: AppTheme.primaryColor,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        itemCount: searchState.results.length + (searchState.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          // Loading more indicator
          if (index >= searchState.results.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final tool = searchState.results[index];

          // Section headers
          Widget? header;
          if (index == 0 && tool.isBuddy && searchState.buddyToolCount > 0) {
            header = _buildSectionHeader('From Your Buddies', searchState.buddyToolCount, isDark);
          } else if (index == searchState.buddyToolCount && searchState.buddyToolCount > 0 && !tool.isBuddy) {
            header = _buildSectionHeader('Nearby Tools', searchState.otherToolCount, isDark);
          } else if (index == 0 && !tool.isBuddy) {
            header = _buildSectionHeader('Nearby Tools', searchState.results.length, isDark);
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (header != null) header,
              ToolSearchCard(
                tool: tool,
                onTap: () {
                  context.push('/search/user/${tool.ownerId}?mode=borrow');
                },
              ).animate().fadeIn(
                    delay: Duration(milliseconds: 50 * (index % 10)),
                    duration: 300.ms,
                  ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNoLocationState(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(isDark ? 0.2 : 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_off_rounded,
                size: 40,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Location Required',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppTheme.textPrimaryDark
                    : AppTheme.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              FunnyMessages.noLocationSet,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppTheme.textSecondaryDark
                    : AppTheme.textSecondaryLight,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Set My Location',
              icon: Icons.my_location,
              onPressed: _showLocationDialog,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildSectionHeader(String title, int count, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radius2xl),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
