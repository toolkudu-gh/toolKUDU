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
      final response = await _apiService.get(
        '/api/sharing/requests/incoming',
        queryParameters: status != null ? {'status': status} : null,
      );

      final items = response['items'] as List? ?? [];
      final requests = items
          .map((e) => LendingRequest.fromJson(e as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        incomingRequests: requests,
        isLoading: false,
      );
    } catch (e) {
      print('Failed to load incoming requests: $e');
      state = state.copyWith(
        incomingRequests: [],
        isLoading: false,
      );
    }
  }

  Future<void> loadOutgoingRequests({String? status}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _apiService.get(
        '/api/sharing/requests/outgoing',
        queryParameters: status != null ? {'status': status} : null,
      );

      final items = response['items'] as List? ?? [];
      final requests = items
          .map((e) => LendingRequest.fromJson(e as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        outgoingRequests: requests,
        isLoading: false,
      );
    } catch (e) {
      print('Failed to load outgoing requests: $e');
      state = state.copyWith(
        outgoingRequests: [],
        isLoading: false,
      );
    }
  }

  Future<void> loadLentOutTools() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _apiService.get('/api/sharing/lent-out');

      final items = response['items'] as List? ?? [];
      final tools = items
          .map((e) => LentOutTool.fromJson(e as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        lentOutTools: tools,
        isLoading: false,
      );
    } catch (e) {
      print('Failed to load lent out tools: $e');
      state = state.copyWith(
        lentOutTools: [],
        isLoading: false,
      );
    }
  }

  Future<void> loadBorrowedTools() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _apiService.get('/api/sharing/borrowed');

      final items = response['items'] as List? ?? [];
      final tools = items
          .map((e) => BorrowedTool.fromJson(e as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        borrowedTools: tools,
        isLoading: false,
      );
    } catch (e) {
      print('Failed to load borrowed tools: $e');
      state = state.copyWith(
        borrowedTools: [],
        isLoading: false,
      );
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
      await _apiService.post(
        '/api/sharing/tools/$toolId/request',
        data: message != null ? {'message': message} : null,
      );

      await loadOutgoingRequests();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> respondToRequest(String requestId, {required bool approve, String? message}) async {
    try {
      await _apiService.post(
        '/api/sharing/requests/$requestId/respond',
        data: {'approve': approve, if (message != null) 'message': message},
      );

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
      await _apiService.post('/api/sharing/requests/$requestId/return');

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
  final api = ref.watch(apiServiceProvider);

  try {
    final response = await api.get('/api/users/$userId/toolboxes');

    final items = response['items'] as List? ?? [];
    return items.map((e) => Toolbox.fromJson(e as Map<String, dynamic>)).toList();
  } catch (e) {
    print('Failed to load user toolboxes: $e');
    return [];
  }
});

// Provider for fetching tools in a user's toolbox
final toolboxToolsProvider = FutureProvider.family<List<Tool>, String>((ref, toolboxId) async {
  final api = ref.watch(apiServiceProvider);

  try {
    final response = await api.get('/api/toolboxes/$toolboxId/tools');

    final items = response['items'] as List? ?? [];
    return items.map((e) => Tool.fromJson(e as Map<String, dynamic>)).toList();
  } catch (e) {
    print('Failed to load toolbox tools: $e');
    return [];
  }
});

// Provider for fetching user profile
final userProfileProvider = FutureProvider.family<User?, String>((ref, userId) async {
  final api = ref.watch(apiServiceProvider);

  try {
    final response = await api.get('/api/users/$userId');
    return User.fromJson(response);
  } catch (e) {
    print('Failed to load user profile: $e');
    return null;
  }
});
