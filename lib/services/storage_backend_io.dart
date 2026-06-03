import 'dart:convert';
import 'dart:io';

class StorageBackend {
  Future<String?> read(String key) async {
    final data = await _readAll();
    return data[key];
  }

  Future<void> write(String key, String value) async {
    final data = await _readAll();
    data[key] = value;
    await _writeAll(data);
  }

  Future<void> remove(String key) async {
    final data = await _readAll();
    data.remove(key);
    await _writeAll(data);
  }

  Future<Map<String, String>> _readAll() async {
    final file = await _storageFile();
    if (!await file.exists()) return {};

    final raw = await file.readAsString();
    if (raw.trim().isEmpty) return {};

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((key, value) => MapEntry(key, value as String));
  }

  Future<void> _writeAll(Map<String, String> data) async {
    final file = await _storageFile();
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(data), flush: true);
  }

  Future<File> _storageFile() async {
    final root = _storageRoot();
    final directory = Directory('$root${Platform.pathSeparator}Dandi Bot');
    return File('${directory.path}${Platform.pathSeparator}storage.json');
  }

  String _storageRoot() {
    if (Platform.isWindows) {
      return Platform.environment['LOCALAPPDATA'] ??
          Platform.environment['APPDATA'] ??
          Directory.current.path;
    }

    return Platform.environment['HOME'] ??
        Platform.environment['TMPDIR'] ??
        Directory.systemTemp.path;
  }
}
