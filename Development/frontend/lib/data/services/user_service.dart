import '../models/user_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UserService {
  final String baseurl;

  UserService({required this.baseurl});

  Future<List<User>> fetchUsers(int userId) async {
    final url = Uri.parse('$baseurl/getUser?id=$userId');
    print('API Call URL: $url');

    try {
      final response = await http.get(url);
      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic decodedResponse = json.decode(response.body);

        // ✅ Ensure response contains "user"
        if (decodedResponse is Map<String, dynamic> &&
            decodedResponse.containsKey('user')) {
          final userJson = decodedResponse['user'];
          return [User.fromJson(userJson)]; // Convert single user into List
        } else {
          throw Exception('Unexpected API response format');
        }
      } else {
        throw Exception(
            'Failed to fetch user: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching user: $e');
    }
  }
}
