import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class DriverChatGroupsScreen extends StatefulWidget {
  const DriverChatGroupsScreen({super.key});

  @override
  State<DriverChatGroupsScreen> createState() => _DriverChatGroupsScreenState();
}

class _DriverChatGroupsScreenState extends State<DriverChatGroupsScreen> {
  List<dynamic> chatGroups = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchChatGroups();
  }

  Future<void> fetchChatGroups() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:3089/api/v1/groups/user/2'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          chatGroups = data['chatGroups'];
          isLoading = false;
        });
      } else {
        print('Failed to load chat groups');
      }
    } catch (e) {
      print('Error fetching chat groups: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Chat Groups'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: chatGroups.length,
              itemBuilder: (context, index) {
                final group = chatGroups[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(group['name']),
                    subtitle: Text('Vehicle: ${group['vehicleInfo']['vehicleNo']}'),
                    onTap: () {
                      // TODO: Navigate to specific chat screen with group['id']
                    },
                  ),
                );
              },
            ),
    );
  }
}
