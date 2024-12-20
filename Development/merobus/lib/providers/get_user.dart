import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/loginModel.dart';
import '../routes/routes.dart';

Future<User> getUser() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  final response = await http.get(Uri.parse('${Routes.route}user'), headers: {'Authorization': 'Bearer $token'});
  return User.fromJson(jsonDecode(response.body));
}