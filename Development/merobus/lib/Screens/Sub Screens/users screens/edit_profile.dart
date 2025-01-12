import 'dart:convert';  // For encoding JSON
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:http_parser/http_parser.dart';

import '../../../routes/routes.dart';

class UpdateUserScreen extends StatefulWidget {
  const UpdateUserScreen({super.key, required this.userId});
  final int userId;

  @override
  _UpdateUserScreenState createState() => _UpdateUserScreenState();
}

class _UpdateUserScreenState extends State<UpdateUserScreen> {
  File? _image;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  // Pick image from gallery
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  // Update user with image, send data in body as JSON
  Future<void> _updateUser() async {
    // Replace with your public ngrok URL or backend URL
    final uri = Uri.parse('${Routes.route}/updateUser');
    
    // Prepare the JSON data
    Map<String, String> userData = {
      'id': widget.userId.toString(),
      'username': _usernameController.text,
      'email': _emailController.text,
      'phone': _phoneController.text,
      'address': _addressController.text,
    };

    try {
      // Create multipart request to handle both JSON and file
      var request = http.MultipartRequest('PUT', uri)
        ..fields.addAll(userData);

      // If an image is selected, add it to the request
      if (_image != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'image', // 'image' should match the backend form field name
            _image!.path,
            contentType: MediaType('image', 'jpeg'), // Change 'jpeg' if different image format
          ),
        );
      }

      // Send the request
      final response = await request.send();

      // Handle response
      if (response.statusCode == 200) {
        print('User updated successfully');
        ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(content: Text('User updated successfully')),
        );
      } else {
        print('Failed to update user');
        ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(content: Text('Failed to update user')),
        );
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(content: Text('An error occurred while updating the user')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Update User')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(labelText: 'Phone'),
            ),
            TextField(
              controller: _addressController,
              decoration: InputDecoration(labelText: 'Address'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('Pick Image'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateUser,
              child: Text('Update User'),
            ),
          ],
        ),
      ),
    );
  }
}