import 'dart:io';
import '../models/user_model.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';

class UserService {
  final String baseurl;

  UserService({required this.baseurl});

  Future<List<User>> fetchUsers(int userId) async {
    final url = Uri.parse('$baseurl/getUser?id=$userId');

    try {
      final response = await http.get(url);

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

  Future<Map<String, dynamic>> updateUser(int userId, String username,
      String email, String address, String phone, File? imagePath) async {
    final url = Uri.parse('$baseurl/updateUser');

    try {
      // Create a multipart request
      var request = http.MultipartRequest('PUT', url);

      // Add text fields
      request.fields['id'] = userId.toString();
      request.fields['username'] = username;
      request.fields['email'] = email;
      request.fields['address'] = address;
      request.fields['phone'] = phone;

      // Add image file
      request.files.add(await http.MultipartFile.fromPath(
        'images', // This key must match the backend's field name
        imagePath!.path,
        contentType:
            MediaType('image', 'jpeg'), // Adjust content type if needed
      ));

      // Send the request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        print('User updated successfully');
        return json.decode(response.body);
      } else {
        print('Failed to update user: ${response.statusCode}');
        return {'error': 'Failed to update user'};
      }
    } catch (e) {
      print('Error updating user: $e');
      throw Exception('Error updating user: $e');
    }
  }
}
