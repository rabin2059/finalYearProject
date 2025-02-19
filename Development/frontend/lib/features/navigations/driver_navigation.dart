import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/authentication/providers/auth_provider.dart';

class DriverNavigation extends ConsumerStatefulWidget {
  const DriverNavigation({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _DriverNavigationState();
}

class _DriverNavigationState extends ConsumerState<DriverNavigation> {

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: Center(
        child: Text(authState.currentRole.toString()),
      ),
    );
  }
}