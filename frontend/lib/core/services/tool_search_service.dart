import '../models/tool_search_result.dart';

/// Service for searching tools by location
class ToolSearchService {
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
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 600));

    // Mock data for development
    final mockTools = _generateMockTools(latitude, longitude);

    // Filter by query
    var filtered = mockTools;
    if (query != null && query.isNotEmpty) {
      final lowerQuery = query.toLowerCase();
      filtered = filtered.where((tool) {
        return tool.toolName.toLowerCase().contains(lowerQuery) ||
            (tool.brand?.toLowerCase().contains(lowerQuery) ?? false) ||
            (tool.model?.toLowerCase().contains(lowerQuery) ?? false) ||
            (tool.category?.toLowerCase().contains(lowerQuery) ?? false);
      }).toList();
    }

    // Filter by category
    if (category != null && category.isNotEmpty) {
      filtered = filtered.where((tool) => tool.category == category).toList();
    }

    // Sort: buddies first, then by distance
    filtered.sort((a, b) {
      if (a.isBuddy && !b.isBuddy) return -1;
      if (!a.isBuddy && b.isBuddy) return 1;
      return a.distanceMiles.compareTo(b.distanceMiles);
    });

    // Paginate
    final start = offset;
    final end = (offset + limit).clamp(0, filtered.length);
    if (start >= filtered.length) return [];

    return filtered.sublist(start, end);
  }

  /// Get available tool categories
  Future<List<ToolCategory>> getCategories() async {
    await Future.delayed(const Duration(milliseconds: 200));

    return const [
      ToolCategory(id: 'power_tools', name: 'Power Tools', toolCount: 45),
      ToolCategory(id: 'hand_tools', name: 'Hand Tools', toolCount: 78),
      ToolCategory(id: 'garden', name: 'Garden & Outdoor', toolCount: 32),
      ToolCategory(id: 'automotive', name: 'Automotive', toolCount: 28),
      ToolCategory(id: 'woodworking', name: 'Woodworking', toolCount: 41),
      ToolCategory(id: 'electrical', name: 'Electrical', toolCount: 19),
      ToolCategory(id: 'plumbing', name: 'Plumbing', toolCount: 15),
      ToolCategory(id: 'painting', name: 'Painting', toolCount: 22),
    ];
  }

  /// Generate mock tools for development
  List<ToolSearchResult> _generateMockTools(double lat, double lng) {
    return [
      // Buddy tools (shown first)
      ToolSearchResult(
        toolId: 't1',
        toolName: 'DeWalt 20V Drill',
        description: 'Powerful cordless drill, great for home projects',
        category: 'power_tools',
        brand: 'DeWalt',
        model: 'DCD771C2',
        toolboxId: 'tb1',
        toolboxName: 'Power Tools',
        ownerId: 'u1',
        ownerUsername: 'john_doe',
        ownerDisplayName: 'John Doe',
        distanceMiles: 2.3,
        isBuddy: true,
        isAvailable: true,
      ),
      ToolSearchResult(
        toolId: 't2',
        toolName: 'Makita Circular Saw',
        description: '7-1/4" circular saw with electric brake',
        category: 'power_tools',
        brand: 'Makita',
        model: '5007F',
        toolboxId: 'tb1',
        toolboxName: 'Power Tools',
        ownerId: 'u1',
        ownerUsername: 'john_doe',
        ownerDisplayName: 'John Doe',
        distanceMiles: 2.3,
        isBuddy: true,
        isAvailable: true,
      ),
      ToolSearchResult(
        toolId: 't3',
        toolName: 'Socket Wrench Set',
        description: '150-piece mechanics tool set',
        category: 'automotive',
        brand: 'Craftsman',
        model: 'CMMT12021',
        toolboxId: 'tb2',
        toolboxName: 'Garage Tools',
        ownerId: 'u2',
        ownerUsername: 'jane_smith',
        ownerDisplayName: 'Jane Smith',
        distanceMiles: 4.7,
        isBuddy: true,
        isAvailable: true,
      ),

      // Non-buddy tools (sorted by distance)
      ToolSearchResult(
        toolId: 't4',
        toolName: 'Milwaukee Impact Driver',
        description: 'M18 FUEL 1/4" Hex Impact Driver',
        category: 'power_tools',
        brand: 'Milwaukee',
        model: '2853-20',
        toolboxId: 'tb3',
        toolboxName: 'Workshop',
        ownerId: 'u3',
        ownerUsername: 'bob_builder',
        ownerDisplayName: 'Bob Builder',
        distanceMiles: 1.2,
        isBuddy: false,
        isAvailable: true,
      ),
      ToolSearchResult(
        toolId: 't5',
        toolName: 'Ryobi Pressure Washer',
        description: '2000 PSI Electric Pressure Washer',
        category: 'garden',
        brand: 'Ryobi',
        model: 'RY142022VNM',
        toolboxId: 'tb4',
        toolboxName: 'Outdoor Equipment',
        ownerId: 'u4',
        ownerUsername: 'mike_tools',
        ownerDisplayName: 'Mike Johnson',
        distanceMiles: 3.8,
        isBuddy: false,
        isAvailable: true,
      ),
      ToolSearchResult(
        toolId: 't6',
        toolName: 'Bosch Jigsaw',
        description: 'Top-Handle Jig Saw with case',
        category: 'power_tools',
        brand: 'Bosch',
        model: 'JS470E',
        toolboxId: 'tb5',
        toolboxName: 'Woodworking',
        ownerId: 'u5',
        ownerUsername: 'sarah_maker',
        ownerDisplayName: 'Sarah Maker',
        distanceMiles: 5.1,
        isBuddy: false,
        isAvailable: true,
      ),
      ToolSearchResult(
        toolId: 't7',
        toolName: 'Werner Step Ladder',
        description: '6 ft Aluminum Step Ladder',
        category: 'hand_tools',
        brand: 'Werner',
        model: '366',
        toolboxId: 'tb6',
        toolboxName: 'Home Improvement',
        ownerId: 'u6',
        ownerUsername: 'dave_diy',
        ownerDisplayName: 'Dave Wilson',
        distanceMiles: 7.2,
        isBuddy: false,
        isAvailable: true,
      ),
      ToolSearchResult(
        toolId: 't8',
        toolName: 'Honda Generator',
        description: '3000W Portable Inverter Generator',
        category: 'power_tools',
        brand: 'Honda',
        model: 'EU3000IS',
        toolboxId: 'tb7',
        toolboxName: 'Emergency Gear',
        ownerId: 'u7',
        ownerUsername: 'prep_pete',
        ownerDisplayName: 'Pete Anderson',
        distanceMiles: 12.5,
        isBuddy: false,
        isAvailable: true,
      ),
      ToolSearchResult(
        toolId: 't9',
        toolName: 'Husqvarna Chainsaw',
        description: '18" Gas Chainsaw',
        category: 'garden',
        brand: 'Husqvarna',
        model: '450 Rancher',
        toolboxId: 'tb8',
        toolboxName: 'Yard Tools',
        ownerId: 'u8',
        ownerUsername: 'tree_guy',
        ownerDisplayName: 'Tom Greene',
        distanceMiles: 18.3,
        isBuddy: false,
        isAvailable: true,
      ),
      ToolSearchResult(
        toolId: 't10',
        toolName: 'Snap-on Torque Wrench',
        description: '1/2" Drive Torque Wrench',
        category: 'automotive',
        brand: 'Snap-on',
        model: 'ATECH3FR250B',
        toolboxId: 'tb9',
        toolboxName: 'Auto Shop',
        ownerId: 'u9',
        ownerUsername: 'auto_alex',
        ownerDisplayName: 'Alex Mechanic',
        distanceMiles: 24.7,
        isBuddy: false,
        isAvailable: true,
      ),
      ToolSearchResult(
        toolId: 't11',
        toolName: 'Festool Track Saw',
        description: 'TS 55 REQ Plunge Cut Track Saw',
        category: 'woodworking',
        brand: 'Festool',
        model: 'TS 55 REQ',
        toolboxId: 'tb10',
        toolboxName: 'Fine Woodworking',
        ownerId: 'u10',
        ownerUsername: 'wood_master',
        ownerDisplayName: 'Chris Carpenter',
        distanceMiles: 35.2,
        isBuddy: false,
        isAvailable: true,
      ),
      ToolSearchResult(
        toolId: 't12',
        toolName: 'Tile Wet Saw',
        description: '10" Wet Tile Saw with Stand',
        category: 'hand_tools',
        brand: 'DEWALT',
        model: 'D24000S',
        toolboxId: 'tb11',
        toolboxName: 'Tile Tools',
        ownerId: 'u11',
        ownerUsername: 'tile_pro',
        ownerDisplayName: 'Maria Tiles',
        distanceMiles: 42.8,
        isBuddy: false,
        isAvailable: false,
      ),
    ];
  }
}
