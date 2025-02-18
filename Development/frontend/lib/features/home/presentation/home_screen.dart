import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/authentication/providers/auth_provider.dart';

import '../../authentication/presentation/login_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {


  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    if (!authState.isLoggedIn) {
      return LoginScreen();
    }
    return Center(
      child: Text('Welcome, ${authState.userId}'),
    );
    return Scaffold();

  }
}