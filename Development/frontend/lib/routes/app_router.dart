import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/user/Driver/add%20route/presentation/add_route_screen.dart';
import 'package:frontend/user/Driver/add%20vehicle/presentation/add_vehicle.dart';
import 'package:frontend/user/Passenger/booking%20lists/presentation/booking_list_screen.dart';
import 'package:frontend/user/Passenger/book%20vehicle/presentation/booking_screen.dart';
import 'package:frontend/user/Passenger/bus%20details/presentation/bus_detail_screen.dart';
import 'package:frontend/user/authentication/sign%20up/presentation/signup.dart';
import 'package:frontend/user/chat/presentation/chat_screen.dart';
import 'package:frontend/user/Passenger/map/presentation/map_screen.dart';
import 'package:frontend/user/Passenger/payment/presentation/overview_screen.dart';
import 'package:frontend/user/Passenger/payment/presentation/payment_screen.dart';
import 'package:frontend/user/Passenger/profile/presentation/profile_screen.dart';
import 'package:frontend/user/Passenger/role%20change/presentation/role_change_screen.dart';
import 'package:frontend/user/Passenger/setting/presentation/setting_screen.dart';
import 'package:go_router/go_router.dart';

import '../user/authentication/login/providers/auth_provider.dart';
import '../user/authentication/login/presentation/login_screen.dart';
import '../user/navigations/navigation_screen.dart';
import '../get_started_screen.dart';

final goRouter = GoRouter(initialLocation: '/', routes: <RouteBase>[
  GoRoute(
      path: '/',
      name: '/',
      builder: (context, state) => const GetStartedScreen()),
  GoRoute(
      path: '/signup',
      name: '/signup',
      builder: (context, state) => const SignUp()),
  GoRoute(
      path: '/login',
      name: '/login',
      builder: (context, state) => const LoginScreen()),
  GoRoute(
      name: '/navigation',
      path: '/navigation',
      builder: (context, state) => Navigation()),
  GoRoute(
      name: '/addVehicle',
      path: '/addVehicle',
      builder: (context, state) => AddVehicle()),
  GoRoute(
    name: 'addRoute', // ✅ Remove leading slash in the name
    path: '/addRoute/:id', // ✅ Define `:id` as a path parameter
    builder: (context, state) {
      final id = int.tryParse(state.pathParameters['id'] ?? '0') ??
          0; // ✅ Extract ID safely
      return AddRouteScreen(vehicleId: id);
    },
  ),
  GoRoute(
      name: '/profile',
      path: '/profile',
      builder: (context, state) => ProfileScreen()),
  GoRoute(
      name: '/chat', path: '/chat', builder: (context, state) => ChatScreen(roomId: 1, roomName: 'Group Chat',)),
  GoRoute(
      name: '/roleChange',
      path: '/roleChange',
      builder: (context, state) => RoleChangeScreen()),
  GoRoute(
      name: '/bookings',
      path: '/bookings',
      builder: (context, state) => BookingListScreen()),
  GoRoute(
      name: '/map', path: '/map', builder: (context, state) => MapScreens()),
  GoRoute(
    name: '/busDetail', // ✅ Ensure name matches navigation call
    path: '/busDetail/:id', // ✅ Accepts a dynamic ID
    builder: (context, state) {
      final busId =
          int.parse(state.pathParameters['id'] ?? '0'); // ✅ Extract ID
      return BusDetailScreen(busId: busId);
    },
  ),
  GoRoute(
      name: '/book',
      path: '/book/:id', // ✅ Accepts a dynamic ID
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id'] ?? '0');
        return BookingScreen(busId: id);
      }),
  GoRoute(
      name: '/overview',
      path: '/overview/:id', // ✅ Accepts a dynamic ID
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id'] ?? '0');
        return OverviewScreen(bookId: id);
      }),
  GoRoute(
    name: '/payment',
    path: '/payment/:url', // ✅ Accepts URL as a parameter
    builder: (context, state) {
      final String? paymentUrl = state.pathParameters['url']; // ✅ Extract URL

      if (paymentUrl == null || paymentUrl.isEmpty) {
        return Scaffold(
          body: Center(child: Text("Invalid Payment URL")),
        );
      }

      return PaymentScreen(
          paymentUrl: Uri.decodeComponent(paymentUrl)); // ✅ Pass decoded URL
    },
  ),
]);
