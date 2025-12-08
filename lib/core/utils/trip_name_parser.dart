class TripNameParser {
  TripNameParser._();

  /// Extract trip name from various formats:
  /// - Full key format: "trip_{TripName}_refId1_refId2" -> "TripName"
  /// - Simple name: "My Trip" -> "My Trip"
  /// - Empty string: "" -> "New journey !"
  static String getTripName(String tripKeys) {
    if (tripKeys.isEmpty) {
      return 'New journey !';
    }

    // Check if it's a full key format: trip_{name}_...
    final regex = RegExp(r'trip_\{([^}]+)\}');
    final match = regex.firstMatch(tripKeys);
    if (match != null) {
      return match.group(1) ?? tripKeys;
    }

    // If not a key format, return as-is (it's already a simple trip name)
    return tripKeys;
  }

  /// Check if the string is a full key format
  static bool isKeyFormat(String value) {
    return value.startsWith('trip_');
  }
}