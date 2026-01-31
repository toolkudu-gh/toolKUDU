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
import '../../../core/models/user.dart';
import '../../../core/utils/funny_messages.dart';

class SearchScreen extends ConsumerStatefulWidget {
  final bool borrowMode;

  const SearchScreen({super.key, this.borrowMode = false});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  List<User> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.length < 2) return;

    setState(() => _isSearching = true);

    // TODO: Replace with actual API call
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _hasSearched = true;
      _isSearching = false;
      _searchResults = [
        const User(id: 'u1', username: 'john_doe', displayName: 'John Doe', followersCount: 45),
        const User(id: 'u2', username: 'jane_smith', displayName: 'Jane Smith', followersCount: 128),
        const User(id: 'u3', username: 'bob_builder', displayName: 'Bob Builder', followersCount: 89),
      ].where((u) => u.username.contains(query.toLowerCase()) ||
                     (u.displayName?.toLowerCase().contains(query.toLowerCase()) ?? false)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  if (widget.borrowMode) ...[
                    AppIconButton(
                      icon: Icons.arrow_back_rounded,
                      onPressed: () => context.go('/share'),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      widget.borrowMode ? 'Find Someone' : 'Search',
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

            // Borrow mode info banner
            if (widget.borrowMode)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: AppCard(
                  padding: const EdgeInsets.all(12),
                  enableHover: false,
                  backgroundColor: AppTheme.primaryColor.withOpacity(isDark ? 0.15 : 0.08),
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Search for a user to browse their tools and request to borrow',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? AppTheme.textPrimaryDark
                                : AppTheme.textPrimaryLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 100.ms, duration: 300.ms),

            // Search input
            Padding(
              padding: const EdgeInsets.all(20),
              child: AppSearchInput(
                controller: _searchController,
                hint: 'Search by username or name...',
                autofocus: true,
                onChanged: (value) {
                  if (value.length >= 2) {
                    _performSearch(value);
                  }
                },
                onClear: () {
                  setState(() {
                    _searchResults = [];
                    _hasSearched = false;
                  });
                },
              ),
            ).animate().fadeIn(delay: 150.ms, duration: 300.ms),

            // Content
            Expanded(
              child: _buildContent(isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    if (_isSearching) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 3,
        itemBuilder: (context, index) => const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: ListTileSkeleton(showTrailing: true),
        ),
      );
    }

    if (!_hasSearched) {
      return EmptyState(
        icon: Icons.search_rounded,
        title: widget.borrowMode ? 'Search for a user' : 'Find users',
        description: 'Enter at least 2 characters to search',
        compact: true,
      ).animate().fadeIn(duration: 300.ms);
    }

    if (_searchResults.isEmpty) {
      return EmptyState.noResults(
        title: 'No users found',
        description: FunnyMessages.noSearchResults,
      ).animate().fadeIn(duration: 300.ms);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        return _buildUserCard(user, isDark, index);
      },
    );
  }

  Widget _buildUserCard(User user, bool isDark, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(16),
        onTap: () {
          if (widget.borrowMode) {
            context.go('/search/user/${user.id}?mode=borrow');
          } else {
            context.go('/search/user/${user.id}');
          }
        },
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppTheme.primaryColor.withOpacity(isDark ? 0.2 : 0.1),
              backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
              child: user.avatarUrl == null
                  ? Text(
                      user.username[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayNameOrUsername,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppTheme.textPrimaryDark
                          : AppTheme.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${user.username}',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppTheme.textSecondaryDark
                          : AppTheme.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.borrowMode)
              Icon(
                Icons.chevron_right_rounded,
                color: isDark
                    ? AppTheme.textMutedDark
                    : AppTheme.textMutedLight,
              )
            else
              AppButton(
                label: 'Follow',
                variant: AppButtonVariant.outline,
                size: AppButtonSize.sm,
                onPressed: () {
                  // TODO: Follow user
                },
              ),
          ],
        ),
      ),
    ).animate().fadeIn(
          delay: Duration(milliseconds: 200 + index * 50),
          duration: 300.ms,
        ).slideX(
          begin: 0.1,
          end: 0,
          delay: Duration(milliseconds: 200 + index * 50),
          duration: 300.ms,
          curve: Curves.easeOutCubic,
        );
  }
}
