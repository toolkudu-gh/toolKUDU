import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/user.dart';
import '../../../core/services/api_service.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/funny_snackbar.dart';
import '../../search/widgets/user_search_dialog.dart';

// Provider for fetching current user's buddies
final myBuddiesProvider = FutureProvider<List<User>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  try {
    final response = await api.get('/api/users/me/buddies');
    final items = response['items'] as List? ?? [];
    return items.map((e) => User.fromJson(e as Map<String, dynamic>)).toList();
  } catch (e) {
    print('Failed to fetch buddies: $e');
    return [];
  }
});

// Provider for fetching incoming buddy requests
final incomingBuddyRequestsProvider = FutureProvider<List<BuddyRequest>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  try {
    final response = await api.get('/api/buddy-requests', queryParameters: {'type': 'incoming'});
    final items = response['items'] as List? ?? [];
    return items.map((e) => BuddyRequest.fromJson(e as Map<String, dynamic>)).toList();
  } catch (e) {
    print('Failed to fetch incoming requests: $e');
    return [];
  }
});

// Provider for fetching outgoing buddy requests
final outgoingBuddyRequestsProvider = FutureProvider<List<BuddyRequest>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  try {
    final response = await api.get('/api/buddy-requests', queryParameters: {'type': 'outgoing'});
    final items = response['items'] as List? ?? [];
    return items.map((e) => BuddyRequest.fromJson(e as Map<String, dynamic>)).toList();
  } catch (e) {
    print('Failed to fetch outgoing requests: $e');
    return [];
  }
});

// Buddy request model
class BuddyRequest {
  final String id;
  final String requesterId;
  final String targetId;
  final String status;
  final DateTime createdAt;
  final DateTime? respondedAt;
  final User user;

  const BuddyRequest({
    required this.id,
    required this.requesterId,
    required this.targetId,
    required this.status,
    required this.createdAt,
    this.respondedAt,
    required this.user,
  });

  factory BuddyRequest.fromJson(Map<String, dynamic> json) {
    return BuddyRequest(
      id: json['id'] as String,
      requesterId: json['requesterId'] as String,
      targetId: json['targetId'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      respondedAt: json['respondedAt'] != null
          ? DateTime.parse(json['respondedAt'] as String)
          : null,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

class BuddiesScreen extends ConsumerWidget {
  const BuddiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Header - now main tab style
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tool Buddies',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppTheme.textPrimaryDark
                            : AppTheme.textPrimaryLight,
                      ),
                    ),
                    AppIconButton(
                      icon: Icons.person_add_outlined,
                      tooltip: 'Find Buddies',
                      onPressed: () => UserSearchDialog.show(context),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms),

              const SizedBox(height: 16),

              // Tab Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(
                      color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                    ),
                  ),
                  child: TabBar(
                    indicator: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd - 2),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicatorPadding: const EdgeInsets.all(4),
                    labelColor: Colors.white,
                    unselectedLabelColor: isDark
                        ? AppTheme.textSecondaryDark
                        : AppTheme.textSecondaryLight,
                    labelStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(text: 'My Buddies'),
                      Tab(text: 'Requests'),
                      Tab(text: 'Sent'),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 100.ms, duration: 300.ms),

              const SizedBox(height: 16),

              // Tab Content
              Expanded(
                child: TabBarView(
                  children: [
                    _BuddiesTab(),
                    _IncomingRequestsTab(),
                    _OutgoingRequestsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BuddiesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final buddiesAsync = ref.watch(myBuddiesProvider);

    return buddiesAsync.when(
      data: (buddies) {
        if (buddies.isEmpty) {
          return EmptyState.noBuddies(
            actionLabel: 'Find Tool Buddies',
            onAction: () => UserSearchDialog.show(context),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.refresh(myBuddiesProvider.future),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            itemCount: buddies.length,
            itemBuilder: (context, index) {
              final buddy = buddies[index];
              return _buildUserCard(
                context,
                ref,
                isDark,
                user: buddy,
                index: index,
                trailing: PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: isDark
                        ? AppTheme.textSecondaryDark
                        : AppTheme.textSecondaryLight,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  onSelected: (value) async {
                    if (value == 'view') {
                      context.go('/search/user/${buddy.id}');
                    } else if (value == 'borrow') {
                      context.go('/search/user/${buddy.id}?mode=borrow');
                    } else if (value == 'remove') {
                      await _removeBuddy(context, ref, buddy.id);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(
                            Icons.person_outlined,
                            size: 20,
                            color: isDark
                                ? AppTheme.textSecondaryDark
                                : AppTheme.textSecondaryLight,
                          ),
                          const SizedBox(width: 12),
                          const Text('View Profile'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'borrow',
                      child: Row(
                        children: [
                          Icon(
                            Icons.handshake_outlined,
                            size: 20,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Request Tool',
                            style: TextStyle(color: AppTheme.primaryColor),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'remove',
                      child: Row(
                        children: [
                          Icon(
                            Icons.person_remove_outlined,
                            size: 20,
                            color: AppTheme.errorColor,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Remove Buddy',
                            style: TextStyle(color: AppTheme.errorColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
      loading: () => _buildLoadingState(),
      error: (error, stack) => EmptyState.error(
        title: 'Failed to load buddies',
        actionLabel: 'Retry',
        onAction: () => ref.refresh(myBuddiesProvider),
      ),
    );
  }

  Future<void> _removeBuddy(BuildContext context, WidgetRef ref, String buddyId) async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.delete('/api/users/me/buddies/$buddyId');
      ref.invalidate(myBuddiesProvider);
      if (context.mounted) {
        FunnySnackBar.showSuccess(context, customMessage: 'Buddy removed');
      }
    } catch (e) {
      if (context.mounted) {
        FunnySnackBar.showError(context, customMessage: 'Failed to remove buddy');
      }
    }
  }
}

class _IncomingRequestsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final requestsAsync = ref.watch(incomingBuddyRequestsProvider);

    return requestsAsync.when(
      data: (requests) {
        if (requests.isEmpty) {
          return const EmptyState(
            icon: Icons.people_outline,
            title: 'No buddy requests',
            description: 'When someone wants to be your Tool Buddy, they\'ll appear here',
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.refresh(incomingBuddyRequestsProvider.future),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return _buildUserCard(
                context,
                ref,
                isDark,
                user: request.user,
                index: index,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppButton(
                      label: 'Accept',
                      variant: AppButtonVariant.primary,
                      size: AppButtonSize.sm,
                      onPressed: () => _respondToRequest(context, ref, request.id, accept: true),
                    ),
                    const SizedBox(width: 8),
                    AppButton(
                      label: 'Decline',
                      variant: AppButtonVariant.ghost,
                      size: AppButtonSize.sm,
                      onPressed: () => _respondToRequest(context, ref, request.id, accept: false),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
      loading: () => _buildLoadingState(),
      error: (error, stack) => EmptyState.error(
        title: 'Failed to load requests',
        actionLabel: 'Retry',
        onAction: () => ref.refresh(incomingBuddyRequestsProvider),
      ),
    );
  }

  Future<void> _respondToRequest(
    BuildContext context,
    WidgetRef ref,
    String requestId, {
    required bool accept,
  }) async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.put('/api/buddy-requests/$requestId', data: {'accept': accept});
      ref.invalidate(incomingBuddyRequestsProvider);
      ref.invalidate(myBuddiesProvider);
      if (context.mounted) {
        if (accept) {
          FunnySnackBar.buddyAdded(context);
        } else {
          FunnySnackBar.showSuccess(context, customMessage: 'Request declined');
        }
      }
    } catch (e) {
      if (context.mounted) {
        FunnySnackBar.showError(context, customMessage: 'Failed to respond to request');
      }
    }
  }
}

class _OutgoingRequestsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final requestsAsync = ref.watch(outgoingBuddyRequestsProvider);

    return requestsAsync.when(
      data: (requests) {
        if (requests.isEmpty) {
          return EmptyState(
            icon: Icons.people_outline,
            title: 'No sent requests',
            description: 'Your pending buddy requests will appear here',
            actionLabel: 'Find Tool Buddies',
            onAction: () => UserSearchDialog.show(context),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.refresh(outgoingBuddyRequestsProvider.future),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return _buildUserCard(
                context,
                ref,
                isDark,
                user: request.user,
                index: index,
                trailing: AppButton(
                  label: 'Pending',
                  variant: AppButtonVariant.outline,
                  size: AppButtonSize.sm,
                  onPressed: null, // Disabled - just shows status
                ),
              );
            },
          ),
        );
      },
      loading: () => _buildLoadingState(),
      error: (error, stack) => EmptyState.error(
        title: 'Failed to load requests',
        actionLabel: 'Retry',
        onAction: () => ref.refresh(outgoingBuddyRequestsProvider),
      ),
    );
  }
}

Widget _buildLoadingState() {
  return ListView.builder(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
    itemCount: 3,
    itemBuilder: (context, index) => const Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: ListTileSkeleton(showTrailing: true),
    ),
  );
}

Widget _buildUserCard(
  BuildContext context,
  WidgetRef ref,
  bool isDark, {
  required User user,
  required int index,
  Widget? trailing,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: AppCard(
      padding: const EdgeInsets.all(14),
      onTap: () => context.go('/search/user/${user.id}'),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppTheme.primaryColor.withOpacity(isDark ? 0.2 : 0.1),
            backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
            child: user.avatarUrl == null
                ? Text(
                    user.displayNameOrUsername[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 14),
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
          if (trailing != null) trailing,
        ],
      ),
    ),
  ).animate().fadeIn(
        delay: Duration(milliseconds: 150 + index * 50),
        duration: 300.ms,
      ).slideX(
        begin: 0.1,
        end: 0,
        delay: Duration(milliseconds: 150 + index * 50),
        duration: 300.ms,
        curve: Curves.easeOutCubic,
      );
}
