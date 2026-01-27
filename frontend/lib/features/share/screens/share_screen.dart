import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/app_dialog.dart';
import '../../../core/models/lending_request.dart';
import '../../../core/providers/lending_provider.dart';

class ShareScreen extends ConsumerStatefulWidget {
  const ShareScreen({super.key});

  @override
  ConsumerState<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends ConsumerState<ShareScreen> with SingleTickerProviderStateMixin {
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(lendingStateProvider.notifier).loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final lendingState = ref.watch(lendingStateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sharing',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppTheme.textPrimaryDark
                          : AppTheme.textPrimaryLight,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),

            // Tab Pills
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.surfaceDark : AppTheme.backgroundLight,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  border: Border.all(
                    color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                  ),
                ),
                child: Row(
                  children: [
                    _buildTabPill(0, 'Requests', isDark),
                    _buildTabPill(1, 'Lent Out', isDark),
                    _buildTabPill(2, 'Borrowed', isDark),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 100.ms, duration: 300.ms),

            // Content
            Expanded(
              child: IndexedStack(
                index: _selectedTabIndex,
                children: [
                  _buildRequestsTab(context, lendingState, isDark),
                  _buildLentOutTab(context, lendingState, isDark),
                  _buildBorrowedTab(context, lendingState, isDark),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 70),
        child: FloatingActionButton.extended(
          onPressed: () => _startBorrowFlow(context),
          icon: const Icon(Icons.add),
          label: const Text('Request Tool'),
        ).animate().scale(
              delay: 400.ms,
              duration: 300.ms,
              curve: Curves.easeOutBack,
            ),
      ),
    );
  }

  Widget _buildTabPill(int index, String label, bool isDark) {
    final isSelected = _selectedTabIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryColor
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? Colors.white
                  : (isDark
                      ? AppTheme.textSecondaryDark
                      : AppTheme.textSecondaryLight),
            ),
          ),
        ),
      ),
    );
  }

  void _startBorrowFlow(BuildContext context) {
    context.go('/search?mode=borrow');
  }

  Widget _buildRequestsTab(BuildContext context, LendingState state, bool isDark) {
    if (state.isLoading) {
      return _buildLoadingState();
    }

    final incomingPending = state.incomingRequests.where((r) => r.isPending).toList();
    final outgoingPending = state.outgoingRequests.where((r) => r.isPending).toList();

    if (incomingPending.isEmpty && outgoingPending.isEmpty) {
      return EmptyState(
        icon: Icons.inbox_outlined,
        title: 'No pending requests',
        description: 'Tap the button below to request a tool',
        compact: true,
      ).animate().fadeIn(duration: 300.ms);
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(lendingStateProvider.notifier).loadIncomingRequests();
        await ref.read(lendingStateProvider.notifier).loadOutgoingRequests();
      },
      color: AppTheme.primaryColor,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        children: [
          if (incomingPending.isNotEmpty) ...[
            _buildSectionHeader('Incoming Requests', incomingPending.length, isDark),
            ...incomingPending.asMap().entries.map((entry) {
              return _buildIncomingRequestCard(context, entry.value, isDark)
                  .animate()
                  .fadeIn(delay: Duration(milliseconds: 150 + entry.key * 50), duration: 300.ms)
                  .slideX(
                    begin: 0.1,
                    end: 0,
                    delay: Duration(milliseconds: 150 + entry.key * 50),
                    duration: 300.ms,
                    curve: Curves.easeOutCubic,
                  );
            }),
            const SizedBox(height: 24),
          ],
          if (outgoingPending.isNotEmpty) ...[
            _buildSectionHeader('Your Pending Requests', outgoingPending.length, isDark),
            ...outgoingPending.asMap().entries.map((entry) {
              return _buildOutgoingRequestCard(context, entry.value, isDark)
                  .animate()
                  .fadeIn(delay: Duration(milliseconds: 200 + entry.key * 50), duration: 300.ms)
                  .slideX(
                    begin: 0.1,
                    end: 0,
                    delay: Duration(milliseconds: 200 + entry.key * 50),
                    duration: 300.ms,
                    curve: Curves.easeOutCubic,
                  );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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

  Widget _buildIncomingRequestCard(BuildContext context, LendingRequest request, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.primaryColor.withOpacity(isDark ? 0.2 : 0.1),
                  child: Text(
                    request.requester.username[0].toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.requester.displayNameOrUsername,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppTheme.textPrimaryDark
                              : AppTheme.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'wants to borrow: ${request.tool.name}',
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
                StatusBadge.pending(label: 'Pending', small: true),
              ],
            ),
            if (request.message != null && request.message!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.backgroundDark
                      : AppTheme.backgroundLight,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.format_quote,
                      size: 16,
                      color: isDark
                          ? AppTheme.textMutedDark
                          : AppTheme.textMutedLight,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        request.message!,
                        style: TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: isDark
                              ? AppTheme.textSecondaryDark
                              : AppTheme.textSecondaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Decline',
                    variant: AppButtonVariant.outline,
                    onPressed: () => _respondToRequest(request.id, approve: false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    label: 'Approve',
                    onPressed: () => _respondToRequest(request.id, approve: true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutgoingRequestCard(BuildContext context, LendingRequest request, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Icon(
                Icons.build_outlined,
                size: 20,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.tool.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppTheme.textPrimaryDark
                          : AppTheme.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'From: ${request.owner.displayNameOrUsername}',
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
            StatusBadge.pending(label: 'Pending', small: true),
          ],
        ),
      ),
    );
  }

  Future<void> _respondToRequest(String requestId, {required bool approve}) async {
    final result = await ref.read(lendingStateProvider.notifier).respondToRequest(
          requestId,
          approve: approve,
        );

    if (mounted && result) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(approve ? 'Request approved!' : 'Request declined'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildLentOutTab(BuildContext context, LendingState state, bool isDark) {
    if (state.isLoading) {
      return _buildLoadingState();
    }

    if (state.lentOutTools.isEmpty) {
      return EmptyState(
        icon: Icons.share_outlined,
        title: 'No tools currently lent out',
        description: 'Tools you lend to others will appear here',
        compact: true,
      ).animate().fadeIn(duration: 300.ms);
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(lendingStateProvider.notifier).loadLentOutTools(),
      color: AppTheme.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        itemCount: state.lentOutTools.length,
        itemBuilder: (context, index) {
          final tool = state.lentOutTools[index];
          return _buildLentOutCard(context, tool, isDark)
              .animate()
              .fadeIn(delay: Duration(milliseconds: 150 + index * 50), duration: 300.ms)
              .slideX(
                begin: 0.1,
                end: 0,
                delay: Duration(milliseconds: 150 + index * 50),
                duration: 300.ms,
                curve: Curves.easeOutCubic,
              );
        },
      ),
    );
  }

  Widget _buildLentOutCard(BuildContext context, LentOutTool tool, bool isDark) {
    final daysBorrowed = DateTime.now().difference(tool.borrowedAt).inDays;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Icon(
                Icons.build_outlined,
                size: 20,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tool.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppTheme.textPrimaryDark
                          : AppTheme.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Borrowed by: @${tool.borrowerUsername}',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppTheme.textSecondaryDark
                          : AppTheme.textSecondaryLight,
                    ),
                  ),
                  Text(
                    '$daysBorrowed days ago',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppTheme.textMutedDark
                          : AppTheme.textMutedLight,
                    ),
                  ),
                ],
              ),
            ),
            StatusBadge(
              label: 'Lent Out',
              variant: StatusBadgeVariant.primary,
              small: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBorrowedTab(BuildContext context, LendingState state, bool isDark) {
    if (state.isLoading) {
      return _buildLoadingState();
    }

    if (state.borrowedTools.isEmpty) {
      return EmptyState(
        icon: Icons.handshake_outlined,
        title: 'No borrowed tools',
        description: 'Tools you borrow will appear here',
        compact: true,
      ).animate().fadeIn(duration: 300.ms);
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(lendingStateProvider.notifier).loadBorrowedTools(),
      color: AppTheme.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        itemCount: state.borrowedTools.length,
        itemBuilder: (context, index) {
          final tool = state.borrowedTools[index];
          return _buildBorrowedCard(context, tool, isDark)
              .animate()
              .fadeIn(delay: Duration(milliseconds: 150 + index * 50), duration: 300.ms)
              .slideX(
                begin: 0.1,
                end: 0,
                delay: Duration(milliseconds: 150 + index * 50),
                duration: 300.ms,
                curve: Curves.easeOutCubic,
              );
        },
      ),
    );
  }

  Widget _buildBorrowedCard(BuildContext context, BorrowedTool tool, bool isDark) {
    final daysBorrowed = DateTime.now().difference(tool.borrowedAt).inDays;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withOpacity(isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Icon(
                    Icons.build_outlined,
                    size: 20,
                    color: AppTheme.successColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tool.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppTheme.textPrimaryDark
                              : AppTheme.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'From: @${tool.ownerUsername}',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppTheme.textSecondaryDark
                              : AppTheme.textSecondaryLight,
                        ),
                      ),
                      Text(
                        'Borrowed $daysBorrowed days ago',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppTheme.textMutedDark
                              : AppTheme.textMutedLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                label: 'Mark as Returned',
                icon: Icons.keyboard_return,
                variant: AppButtonVariant.outline,
                onPressed: () => _returnTool(tool.lendingRequestId),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _returnTool(String requestId) async {
    final confirmed = await AppDialog.confirm(
      context: context,
      title: 'Return Tool',
      description: 'Mark this tool as returned to the owner?',
      confirmLabel: 'Confirm Return',
      cancelLabel: 'Cancel',
    );

    if (confirmed == true) {
      final result = await ref.read(lendingStateProvider.notifier).returnTool(requestId);
      if (mounted && result) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tool marked as returned!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 3,
      itemBuilder: (context, index) => const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: ListTileSkeleton(showTrailing: true),
      ),
    );
  }
}
