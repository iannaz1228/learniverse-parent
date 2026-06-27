import 'package:shared_preferences/shared_preferences.dart';

abstract final class WalletPin {
  static const _key = 'lv_wallet_pin';

  static Future<bool> isSet() async {
    final p = await SharedPreferences.getInstance();
    return (p.getString(_key) ?? '').length == 4;
  }

  static Future<bool> verify(String pin) async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_key) == pin;
  }

  static Future<void> save(String pin) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, pin);
  }

  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_key);
  }
}
