// Shared JSON parsing utilities — exported for use in widget registry builders.

dynamic jsonLookup(Map<String, dynamic> json, String key) {
  if (json.containsKey(key)) return json[key];
  final lower = key.toLowerCase();
  for (final e in json.entries) {
    if (e.key.toLowerCase() == lower) return e.value;
  }
  return null;
}

String jsonStr(Map<String, dynamic> json, String key) {
  final v = jsonLookup(json, key);
  if (v is String && v.trim().isNotEmpty) return v.trim();
  if (v != null) {
    final s = v.toString().trim();
    if (s.isNotEmpty) return s;
  }
  return '';
}

String? jsonOpt(Map<String, dynamic> json, String key) {
  final v = jsonLookup(json, key);
  if (v == null) return null;
  final s = v.toString().trim();
  return s.isEmpty ? null : s;
}

bool jsonBool(Map<String, dynamic> json, String key) {
  final v = jsonLookup(json, key);
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) {
    final n = v.trim().toLowerCase();
    return n == 'true' || n == '1';
  }
  return false;
}

int? jsonInt(Map<String, dynamic> json, String key) {
  final v = jsonLookup(json, key);
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v.trim());
  return null;
}

DateTime? jsonDateTime(Map<String, dynamic> json, String key) {
  final v = jsonLookup(json, key);
  if (v == null) return null;
  if (v is DateTime) return v.toUtc();
  if (v is String && v.trim().isNotEmpty) return DateTime.tryParse(v.trim())?.toUtc();
  return null;
}

Map<String, dynamic>? jsonMap(Map<String, dynamic> json, String key) {
  final v = jsonLookup(json, key);
  if (v is Map<String, dynamic>) return Map<String, dynamic>.from(v);
  if (v is Map) return Map<String, dynamic>.from(v);
  return null;
}
