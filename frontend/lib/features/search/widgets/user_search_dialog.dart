import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/user.dart';
import '../../../core/services/api_service.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_input.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../core/utils/funny_messages.dart';

/// Full-screen dialog for searching users to add as buddies
class UserSearchDialog extends ConsumerStatefulWidget {
  const UserSearchDialog({super.key});

  /// Show the user search dialog using GoRouter
  static void show(BuildContext context) {
    context.push('/buddies/find');
  }

  @override
  ConsumerState<UserSearchDialog> createState() => _UserSearchDialogState();
}

class _UserSearchDialogState extends ConsumerState<UserSearchDialog> {
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

    try {
      final api = ref.read(apiServiceProvider);
      final response = await api.get('/api/users/search', queryParameters: {'q': query});

      final items = response['items'] as List? ?? [];
      final users = items.map((e) => User.fromJson(e as Map<String, dynamic>)).toList();

      setState(() {
        _hasSearched = true;
        _isSearching = false;
        _searchResults = users;
      });
    } catch (e) {
      print('User search failed: $e');
      setState(() {
        _hasSearched = true;
        _isSearching = false;
        _searchResults = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(
                children: [
                  AppIconButton(
                    icon: Icons.close,
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Find Tool Buddies',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppTheme.textPrimaryDark
                            : AppTheme.textPrimaryLight,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),

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
                  } else {
                    setState(() {
                      _searchResults = [];
                      _hasSearched = false;
                    });
                  }
                },
                onClear: () {
                  setState(() {
                    _searchResults = [];
                    _hasSearched = false;
                  });
                },
              ),
            ).animate().fadeIn(delay: 100.ms, duration: 300.ms),

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
        icon: Icons.person_search_rounded,
        title: 'Search for users',
        description: 'Enter at least 2 characters to find Tool Buddies',
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
          context.go('/search/user/${user.id}');
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
            AppButton(
              label: 'View',
              variant: AppButtonVariant.outline,
              size: AppButtonSize.sm,
              onPressed: () {
                context.go('/search/user/${user.id}');
              },
            ),
          ],
        ),
      ),
    ).animate().fadeIn(
          delay: Duration(milliseconds: 100 + index * 50),
          duration: 300.ms,
        ).slideX(
          begin: 0.1,
          end: 0,
          delay: Duration(milliseconds: 100 + index * 50),
          duration: 300.ms,
          curve: Curves.easeOutCubic,
        );
  }
}
