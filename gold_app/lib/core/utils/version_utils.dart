class VersionUtils {
  /// Compares two version strings (SemVer style).
  /// Returns:
  ///   1 if v1 > v2
  ///  -1 if v1 < v2
  ///   0 if v1 == v2
  static int compare(String v1, String v2) {
    // Clean strings (remove leading 'v' if present)
    final v1Clean = v1.startsWith('v') ? v1.substring(1) : v1;
    final v2Clean = v2.startsWith('v') ? v2.substring(1) : v2;

    // Split by '.' and '+' (to handle build numbers if needed)
    final v1Parts = _getParts(v1Clean);
    final v2Parts = _getParts(v2Clean);

    final length = v1Parts.length > v2Parts.length ? v1Parts.length : v2Parts.length;

    for (var i = 0; i < length; i++) {
        final part1 = i < v1Parts.length ? v1Parts[i] : 0;
        final part2 = i < v2Parts.length ? v2Parts[i] : 0;

        if (part1 > part2) return 1;
        if (part1 < part2) return -1;
    }

    return 0;
  }

  static List<int> _getParts(String version) {
    // Split by common delimiters and handle build numbers
    return version
        .replaceAll('+', '.')
        .split('.')
        .map((p) => int.tryParse(p) ?? 0)
        .toList();
  }

  /// Returns true if [current] is older than [required]
  static bool isUpdateRequired(String current, String required) {
    return compare(current, required) < 0;
  }

  /// Returns true if [current] is older than [latest]
  static bool isUpdateAvailable(String current, String latest) {
    return compare(current, latest) < 0;
  }
}
