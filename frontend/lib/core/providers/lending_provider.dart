import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/lending_request.dart';
import '../models/toolbox.dart';
import '../models/tool.dart';
import '../models/user.dart';
import '../services/api_service.dart';

// State for lending requests
class LendingState {
  final List<LendingRequest> incomingRequests;
  final List<LendingRequest> outgoingRequests;
  final List<LentOutTool> lentOutTools;
  final List<BorrowedTool> borrowedTools;
  final bool isLoading;
  final String? error;

  const LendingState({
    this.incomingRequests = const [],
    this.outgoingRequests = const [],
    this.lentOutTools = const [],
    this.borrowedTools = const [],
    this.isLoading = false,
    this.error,
  });

  LendingState copyWith({
    List<LendingRequest>? incomingRequests,
    List<LendingRequest>? outgoingRequests,
    List<LentOutTool>? lentOutTools,
    List<BorrowedTool>? borrowedTools,
    bool? isLoading,
    String? error,
  }) {
    return LendingState(
      incomingRequests: incomingRequests ?? this.incomingRequests,
      outgoingRequests: outgoingRequests ?? this.outgoingRequests,
      lentOutTools: lentOutTools ?? this.lentOutTools,
      borrowedTools: borrowedTools ?? this.borrowedTools,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class LendingNotifier extends StateNotifier<LendingState> {
  final ApiService _apiService;

  LendingNotifier(this._apiService) : super(const LendingState());

  Future<void> loadIncomingRequests({String? status}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // TODO: Replace with actual API call when backend is connected
      // For now, simulate empty list
      await Future.delayed(const Duration(milliseconds: 300));

      // final response = await _apiService.get(
      //   '/sharing/requests/incoming',
      //   queryParameters: status != null ? {'status': status} : null,
      // );
      // final requests = (response['data'] as List)
      //     .map((e) => LendingRequest.fromJson(e))
      //     .toList();

      state = state.copyWith(
        incomingRequests: [],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadOutgoingRequests({String? status}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // TODO: Replace with actual API call when backend is connected
      await Future.delayed(const Duration(milliseconds: 300));

      // final response = await _apiService.get(
      //   '/sharing/requests/outgoing',
      //   queryParameters: status != null ? {'status': status} : null,
      // );
      // final requests = (response['data'] as List)
      //     .map((e) => LendingRequest.fromJson(e))
      //     .toList();

      state = state.copyWith(
        outgoingRequests: [],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadLentOutTools() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // TODO: Replace with actual API call
      await Future.delayed(const Duration(milliseconds: 300));

      state = state.copyWith(
        lentOutTools: [],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadBorrowedTools() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // TODO: Replace with actual API call
      await Future.delayed(const Duration(milliseconds: 300));

      state = state.copyWith(
        borrowedTools: [],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await Future.wait([
        loadIncomingRequests(),
        loadOutgoingRequests(),
        loadLentOutTools(),
        loadBorrowedTools(),
      ]);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> createBorrowRequest(String toolId, {String? message}) async {
    try {
      // TODO: Replace with actual API call
      await Future.delayed(const Duration(milliseconds: 500));

      // await _apiService.post(
      //   '/sharing/tools/$toolId/request',
      //   data: message != null ? {'message': message} : null,
      // );

      await loadOutgoingRequests();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> respondToRequest(String requestId, {required bool approve, String? message}) async {
    try {
      // TODO: Replace with actual API call
      await Future.delayed(const Duration(milliseconds: 500));

      // await _apiService.post(
      //   '/sharing/requests/$requestId/respond',
      //   data: {'approve': approve, 'message': message},
      // );

      await loadIncomingRequests();
      await loadLentOutTools();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> returnTool(String requestId) async {
    try {
      // TODO: Replace with actual API call
      await Future.delayed(const Duration(milliseconds: 500));

      // await _apiService.post('/sharing/requests/$requestId/return');

      await loadBorrowedTools();
      await loadLentOutTools();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Lending state provider
final lendingStateProvider = StateNotifierProvider<LendingNotifier, LendingState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return LendingNotifier(apiService);
});

// Provider for fetching another user's public toolboxes
final userToolboxesProvider = FutureProvider.family<List<Toolbox>, String>((ref, userId) async {
  // TODO: Replace with actual API call
  await Future.delayed(const Duration(milliseconds: 500));

  // Simulated data for development
  return [
    Toolbox(
      id: 'tb1',
      userId: userId,
      name: 'Power Tools',
      description: 'My collection of power tools',
      visibility: ToolboxVisibility.public,
      toolCount: 5,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
    ),
    Toolbox(
      id: 'tb2',
      userId: userId,
      name: 'Garden Equipment',
      description: 'Lawn mowers, trimmers, etc.',
      visibility: ToolboxVisibility.public,
      toolCount: 3,
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
      updatedAt: DateTime.now(),
    ),
  ];
});

// Provider for fetching tools in a user's toolbox
final toolboxToolsProvider = FutureProvider.family<List<Tool>, String>((ref, toolboxId) async {
  // TODO: Replace with actual API call
  await Future.delayed(const Duration(milliseconds: 500));

  // Simulated data for development
  return [
    Tool(
      id: 't1',
      toolboxId: toolboxId,
      name: 'DeWalt Circular Saw',
      description: '7-1/4" circular saw, great for cutting lumber',
      brand: 'DeWalt',
      category: 'Power Saw',
      isAvailable: true,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
    ),
    Tool(
      id: 't2',
      toolboxId: toolboxId,
      name: 'Makita Drill',
      description: '18V cordless drill with 2 batteries',
      brand: 'Makita',
      category: 'Drill',
      isAvailable: true,
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
      updatedAt: DateTime.now(),
    ),
    Tool(
      id: 't3',
      toolboxId: toolboxId,
      name: 'Bosch Jigsaw',
      description: 'Variable speed jigsaw',
      brand: 'Bosch',
      category: 'Power Saw',
      isAvailable: false,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      updatedAt: DateTime.now(),
    ),
  ];
});

// Provider for fetching user profile with toolbox info
final userProfileProvider = FutureProvider.family<User, String>((ref, userId) async {
  // TODO: Replace with actual API call
  await Future.delayed(const Duration(milliseconds: 500));

  // Simulated data for development
  return User(
    id: userId,
    username: 'john_doe',
    displayName: 'John Doe',
    bio: 'Tool enthusiast and DIY expert',
    followersCount: 128,
    followingCount: 45,
    isFollowing: false,
    isBuddy: false,
  );
});
