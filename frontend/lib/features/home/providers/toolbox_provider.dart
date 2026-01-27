import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/toolbox.dart';
import '../../../core/models/tool.dart';
import '../../../core/services/api_service.dart';

// Toolboxes list provider
final toolboxesProvider = FutureProvider<List<Toolbox>>((ref) async {
  // TODO: Replace with actual API call
  // final api = ref.watch(apiServiceProvider);
  // final response = await api.get('/toolboxes');
  // return (response['data']['items'] as List)
  //     .map((e) => Toolbox.fromJson(e))
  //     .toList();

  // Mock data for development
  await Future.delayed(const Duration(milliseconds: 500));
  return [
    Toolbox(
      id: '1',
      userId: 'user-1',
      name: 'Work Tools',
      description: 'Tools for work projects',
      visibility: ToolboxVisibility.private,
      icon: 'work',
      color: '#2563EB',
      toolCount: 15,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
    ),
    Toolbox(
      id: '2',
      userId: 'user-1',
      name: 'Home Workshop',
      description: 'DIY and home improvement tools',
      visibility: ToolboxVisibility.buddies,
      icon: 'home',
      color: '#10B981',
      toolCount: 23,
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Toolbox(
      id: '3',
      userId: 'user-1',
      name: 'Garden Equipment',
      description: 'Outdoor and gardening tools',
      visibility: ToolboxVisibility.public,
      icon: 'nature',
      color: '#7C3AED',
      toolCount: 8,
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
      updatedAt: DateTime.now().subtract(const Duration(days: 7)),
    ),
  ];
});

// Single toolbox provider
final toolboxProvider = FutureProvider.family<Toolbox?, String>((ref, id) async {
  final toolboxes = await ref.watch(toolboxesProvider.future);
  return toolboxes.where((t) => t.id == id).firstOrNull;
});

// Tools in a toolbox provider
final toolsInToolboxProvider = FutureProvider.family<List<Tool>, String>((ref, toolboxId) async {
  // TODO: Replace with actual API call
  await Future.delayed(const Duration(milliseconds: 300));

  // Mock data
  return [
    Tool(
      id: 't1',
      toolboxId: toolboxId,
      name: 'Cordless Drill',
      description: 'DeWalt 20V MAX cordless drill/driver',
      brand: 'DeWalt',
      model: 'DCD771C2',
      category: 'Power Tools',
      isAvailable: true,
      hasTracker: true,
      images: const [
        ToolImage(id: 'img1', url: 'https://via.placeholder.com/300', orderIndex: 0),
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      updatedAt: DateTime.now(),
    ),
    Tool(
      id: 't2',
      toolboxId: toolboxId,
      name: 'Hammer',
      description: 'Stanley 16oz fiberglass hammer',
      brand: 'Stanley',
      category: 'Hand Tools',
      isAvailable: true,
      hasTracker: false,
      images: const [],
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
      updatedAt: DateTime.now(),
    ),
    Tool(
      id: 't3',
      toolboxId: toolboxId,
      name: 'Circular Saw',
      description: 'Makita 7-1/4" circular saw',
      brand: 'Makita',
      model: '5007MG',
      category: 'Power Tools',
      isAvailable: false,
      hasTracker: true,
      images: const [],
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];
});

// Single tool provider
final toolProvider = FutureProvider.family<Tool?, String>((ref, id) async {
  // TODO: Replace with actual API call
  await Future.delayed(const Duration(milliseconds: 300));

  return Tool(
    id: id,
    toolboxId: '1',
    name: 'Cordless Drill',
    description: 'DeWalt 20V MAX cordless drill/driver with 2 batteries',
    brand: 'DeWalt',
    model: 'DCD771C2',
    category: 'Power Tools',
    serialNumber: 'DW123456789',
    purchaseDate: DateTime(2023, 6, 15),
    purchasePrice: 149.99,
    notes: 'Excellent condition, recently serviced',
    isAvailable: true,
    hasTracker: true,
    images: const [
      ToolImage(id: 'img1', url: 'https://via.placeholder.com/400', orderIndex: 0),
      ToolImage(id: 'img2', url: 'https://via.placeholder.com/400', orderIndex: 1),
    ],
    createdAt: DateTime.now().subtract(const Duration(days: 10)),
    updatedAt: DateTime.now(),
  );
});
