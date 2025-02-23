import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../core/constants.dart';

class OTPService {
  static Future<bool> requestOTP(String email) async {
    if (email.isEmpty) {
      throw Exception('Email cannot be empty');
    }

    final url = Uri.parse('$apiBaseUrl/reqOTP');
    final body = {
      'email': email,
    };

    try {
      final response = await http.post(
        url,
        body: jsonEncode(body),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        throw Exception('Failed to send OTP');
      }
    } catch (e) {
      throw Exception('Network error: ${e.toString()}');
    }
  }
}
