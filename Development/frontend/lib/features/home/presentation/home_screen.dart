import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/components/CustomButton.dart';
import 'package:frontend/features/authentication/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider); // Watch the authentication state

    return Scaffold(
      body: Center(
        child: CustomButton(
          text: "Open Map",
          onPressed: () {
            if (authState.isLoggedIn) {
              context.push("/map"); // ✅ Navigate if authenticated
            } else {
              context.push("/login"); // ❌ Redirect to login if not authenticated
            }
          },
        ),
      ),
    );
  }
}