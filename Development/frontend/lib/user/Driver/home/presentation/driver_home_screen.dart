import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/user/Passenger/map/presentation/map_screen.dart';
import 'package:frontend/user/authentication/login/providers/auth_provider.dart';

import '../../../Passenger/setting/providers/setting_provider.dart';

class DriverHomeScreen extends ConsumerStatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends ConsumerState<DriverHomeScreen> {
  @override
  void initState() {
    super.initState();
    _fetchUserData(); // Fetch user data on init
  }

  Future<void> _fetchUserData() async {
    try {
      final settingNotifier = ref.read(settingProvider.notifier);
      final authState = ref.read(authProvider);
      final userId = authState.userId;

      debugPrint('Fetching user data for userId: $userId'); // Debug print

      if (userId != null) {
        await settingNotifier.fetchUsers(userId);
      } else {
        debugPrint('User ID is null. Cannot fetch user data.');
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider); // Watch the authentication state

    return Scaffold(
      appBar: AppBar(title: const Text("Driver Dashboard")),
      body: Column(
        children: [
          Expanded(child: MapScreens()), // Map at the top
          _buildDriverOptions(context), // Driver-specific actions
        ],
      ),
    );
  }

  Widget _buildDriverOptions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              // Implement accepting ride requests
            },
            child: const Text("View Ride Requests"),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              // Implement earnings feature
            },
            child: const Text("View Earnings"),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              // Implement driver profile editing
            },
            child: const Text("Edit Profile"),
          ),
        ],
      ),
    );
  }
}