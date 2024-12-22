import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:merobus/Components/CustomButton.dart';
import 'package:merobus/Screens/googe%20maps/google_map.dart';
import 'package:merobus/Screens/maps/map.dart';
import 'package:merobus/providers/get_user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Components/AppColors.dart';

class HomeScreen extends StatefulWidget {
  final int dept; // department (role): 1 for Passenger, 2 for Driver

  const HomeScreen({super.key, required this.dept});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    // Check if role is Passenger (1) or Driver (2) and render content accordingly
    if (widget.dept == 1) {
      // Passenger view
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const MapScreens()));
                  },
                  icon: const Icon(Icons.bus_alert,
                      size: 100, color: AppColors.primary)),
              const SizedBox(height: 20),
              const Text("Find Your Bus Here!", style: TextStyle(fontSize: 24)),
              // Additional Passenger-specific content can go here
            ],
          ),
        ),
      );
    } else {
      // Driver view
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.directions_bus, size: 100, color: AppColors.primary),
              SizedBox(height: 20),
              Text("Manage Your Routes!", style: TextStyle(fontSize: 24)),
              // Additional Driver-specific content can go here
            ],
          ),
        ),
      );
    }
  }
}
