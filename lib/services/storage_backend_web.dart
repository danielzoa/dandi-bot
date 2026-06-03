import 'package:web/web.dart' as web;

class StorageBackend {
  static const _prefix = 'dandi_bot.';

  Future<String?> read(String key) async {
    return web.window.localStorage.getItem('$_prefix$key');
  }

  Future<void> write(String key, String value) async {
    web.window.localStorage.setItem('$_prefix$key', value);
  }

  Future<void> remove(String key) async {
    web.window.localStorage.removeItem('$_prefix$key');
  }
}
