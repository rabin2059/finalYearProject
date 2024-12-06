import 'package:flutter/material.dart';

class Test extends StatelessWidget {
  final String email;
  final int role;

  const Test({required this.email, Key? key, required this.role}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Screen')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Email: $email'),
            Text('Role: $role'),
          ],
        ),
      ),
    );
  }
}