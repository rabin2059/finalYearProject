import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsUtil {
  static const String tokenKey = 'accessToken';
  static const String tokenExpiryKey = 'tokenExpiry';
  static const String refreshTokenKey = 'refreshToken';
  static const String roleKey = 'currentRole';
  static const String tripStatusKey = 'tripStatus';

  static Future<void> saveToken(String token, DateTime expiry) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
    await prefs.setString(tokenExpiryKey, expiry.toIso8601String());
  }

  static Future<Map<String, String?>> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      "token": prefs.getString(tokenKey),
      "expiry": prefs.getString(tokenExpiryKey),
    };
  }

  static Future<void> saveRefreshToken(String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(refreshTokenKey, refreshToken);
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(refreshTokenKey);
  }

  static Future<void> saveRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(roleKey, role);
  }

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(roleKey);
  }

  static Future<void> saveTripStatus(String status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tripStatusKey, status);
  }

  static Future<String?> getTripStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tripStatusKey);
  }

  static clearAll() {
    SharedPreferences.getInstance().then((prefs) {
      prefs.clear();
    });
  }
}
