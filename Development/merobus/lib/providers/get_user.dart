import 'package:http/http.dart' as http;
import 'package:merobus/routes/routes.dart';
import 'dart:convert';

import '../models/user_model.dart';

Future<User?> getUser(int userId) async {
  try {
    final url = Uri.parse('${Routes.route}getUser?id=$userId');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      // Parse the response body into a UserModel
      final userModel = UserModel.fromJson(json.decode(response.body));
      return userModel.user;
    } else if (response.statusCode == 404) {
      print("User not found");
      return null;
    } else {
      print("Error: ${response.statusCode} - ${response.body}");
      return null;
    }
  } catch (e) {
    print("Exception occurred: $e");
    return null;
  }
}
