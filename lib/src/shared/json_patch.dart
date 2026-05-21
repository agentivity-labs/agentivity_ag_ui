// RFC 6902 JSON Patch — internal utility shared by AgUiStateController and
// AgUiActivityController. Not exported from the barrel.

class AgUiJsonPatch {
  static Map<String, dynamic> apply(Map<String, dynamic> doc, List<dynamic> ops) {
    var current = _deepCopyMap(doc);
    for (final op in ops) {
      if (op is! Map) continue;
      final operation = op['op']?.toString();
      final path = op['path']?.toString();
      if (operation == null || path == null) continue;
      try {
        current = _applyOp(current, operation, path, op);
      } catch (_) {
        // Best-effort: skip invalid operations.
      }
    }
    return current;
  }

  static Map<String, dynamic> _applyOp(
      Map<String, dynamic> doc, String op, String path, Map<dynamic, dynamic> raw) {
    switch (op) {
      case 'add':
        return _set(doc, path, raw['value'], add: true);
      case 'remove':
        return _remove(doc, path);
      case 'replace':
        return _set(doc, path, raw['value'], add: false);
      case 'move':
        final from = raw['from']?.toString();
        if (from == null) return doc;
        final value = _get(doc, from);
        return _set(_remove(doc, from), path, value, add: true);
      case 'copy':
        final from = raw['from']?.toString();
        if (from == null) return doc;
        return _set(doc, path, _get(doc, from), add: true);
      default:
        return doc;
    }
  }

  static List<String> _segments(String path) {
    if (path.isEmpty || path == '/') return const [];
    return path.substring(1).split('/').map(_unescape).toList();
  }

  static String _unescape(String s) =>
      s.replaceAll('~1', '/').replaceAll('~0', '~');

  static dynamic _get(dynamic node, String path) {
    var current = node;
    for (final seg in _segments(path)) {
      if (current is Map) {
        current = current[seg];
      } else if (current is List) {
        final i = int.tryParse(seg);
        if (i == null || i < 0 || i >= current.length) return null;
        current = current[i];
      } else {
        return null;
      }
    }
    return current;
  }

  static Map<String, dynamic> _set(
      Map<String, dynamic> doc, String path, dynamic value, {required bool add}) {
    final segs = _segments(path);
    if (segs.isEmpty) {
      if (value is Map<String, dynamic>) return Map.from(value);
      if (value is Map) return Map<String, dynamic>.from(value);
      return doc;
    }
    return _setAt(Map<String, dynamic>.from(doc), segs, value, add: add)
        as Map<String, dynamic>;
  }

  static dynamic _setAt(
      dynamic node, List<String> segs, dynamic value, {required bool add}) {
    if (segs.isEmpty) return _deepCopy(value);

    final key = segs[0];
    final rest = segs.sublist(1);

    if (node is Map<String, dynamic>) {
      final copy = Map<String, dynamic>.from(node);
      copy[key] = _setAt(copy[key], rest, value, add: add);
      return copy;
    }

    if (node is List) {
      final copy = List<dynamic>.from(node);
      if (key == '-' && add) {
        copy.add(_setAt(null, rest, value, add: add));
      } else {
        final i = int.tryParse(key);
        if (i != null) {
          if (add && i >= 0 && i <= copy.length) {
            copy.insert(i, _setAt(null, rest, value, add: add));
          } else if (!add && i >= 0 && i < copy.length) {
            copy[i] = _setAt(copy[i], rest, value, add: add);
          }
        }
      }
      return copy;
    }

    if (rest.isEmpty) {
      return <String, dynamic>{key: _deepCopy(value)};
    }
    return <String, dynamic>{key: _setAt(null, rest, value, add: add)};
  }

  static Map<String, dynamic> _remove(Map<String, dynamic> doc, String path) {
    final segs = _segments(path);
    if (segs.isEmpty) return const {};
    return _removeAt(Map<String, dynamic>.from(doc), segs) as Map<String, dynamic>;
  }

  static dynamic _removeAt(dynamic node, List<String> segs) {
    if (segs.isEmpty) return node;

    final key = segs[0];
    final rest = segs.sublist(1);

    if (node is Map<String, dynamic>) {
      final copy = Map<String, dynamic>.from(node);
      if (rest.isEmpty) {
        copy.remove(key);
      } else if (copy.containsKey(key)) {
        copy[key] = _removeAt(copy[key], rest);
      }
      return copy;
    }

    if (node is List) {
      final copy = List<dynamic>.from(node);
      final i = int.tryParse(key);
      if (i != null && i >= 0 && i < copy.length) {
        if (rest.isEmpty) {
          copy.removeAt(i);
        } else {
          copy[i] = _removeAt(copy[i], rest);
        }
      }
      return copy;
    }

    return node;
  }

  static Map<String, dynamic> _deepCopyMap(Map<String, dynamic> m) =>
      m.map((k, v) => MapEntry(k, _deepCopy(v)));

  static dynamic _deepCopy(dynamic v) {
    if (v is Map<String, dynamic>) return _deepCopyMap(v);
    if (v is Map) {
      return Map<String, dynamic>.from(
          v.map((k, val) => MapEntry(k.toString(), _deepCopy(val))));
    }
    if (v is List) return v.map(_deepCopy).toList();
    return v;
  }
}
