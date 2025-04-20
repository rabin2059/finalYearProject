import 'dart:convert';

import 'package:frontend/core/shared_prefs_utils.dart';
import 'package:frontend/data/models/chat_group_model.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ChatGroupService {
  final String baseUrl;

  ChatGroupService({required this.baseUrl});

  Future<List<ChatGroup>> getChatGroups(int id) async {
    try {
      final tokenData = await SharedPrefsUtil.getToken();
      final token = tokenData is Map ? tokenData["token"] : tokenData;
      final uri = Uri.parse('$baseUrl/groups/user/$id');
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse["chatGroups"] == null ||
            jsonResponse["chatGroups"].isEmpty) {
          throw Exception("No Chat Groups Found");
        }

        final List<dynamic> chatList = jsonResponse["chatGroups"];

        return chatList
            .map((chatJson) => ChatGroup.fromJson(chatJson))
            .toList();
      } else {
        throw Exception("API Error: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception('Failed to fetch chat groups.');
    }
  }
}
