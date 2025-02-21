import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/User/booking%20lists/presentation/booking_list_screen.dart';
import 'package:frontend/features/book%20vehicle/presentation/booking_screen.dart';
import 'package:frontend/features/bus%20details/presentation/bus_detail_screen.dart';
import 'package:frontend/features/chat/presentation/chat_screen.dart';
import 'package:frontend/features/map/presentation/map_screen.dart';
import 'package:frontend/features/payment/presentation/overview_screen.dart';
import 'package:frontend/features/payment/presentation/payment_screen.dart';
import 'package:frontend/features/profile/presentation/profile_screen.dart';
import 'package:frontend/features/role%20change/presentation/role_change_screen.dart';
import 'package:frontend/features/setting/presentation/setting_screen.dart';
import 'package:go_router/go_router.dart';

import '../features/authentication/providers/auth_provider.dart';
import '../features/authentication/presentation/login_screen.dart';
import '../features/navigations/navigation_screen.dart';
import '../get_started_screen.dart';

final goRouter = GoRouter(initialLocation: '/', routes: <RouteBase>[
  GoRoute(
      path: '/',
      name: '/',
      builder: (context, state) => const GetStartedScreen()),
  GoRoute(
      path: '/signup',
      name: '/signup',
      builder: (context, state) => const LoginScreen()),
  GoRoute(
      path: '/login',
      name: '/login',
      builder: (context, state) => const LoginScreen()),
  GoRoute(
      name: '/navigation',
      path: '/navigation',
      builder: (context, state) => Navigation()),
  GoRoute(
      name: '/profile',
      path: '/profile',
      builder: (context, state) => ProfileScreen()),
  GoRoute(
      name: '/settings',
      path: '/settings',
      builder: (context, state) => SettingScreen()),
  GoRoute(
      name: '/roleChange',
      path: '/roleChange',
      builder: (context, state) => RoleChangeScreen()),
  GoRoute(
      name: '/bookings',
      path: '/bookings',
      builder: (context, state) => BookingListScreen()),
  GoRoute(
      name: '/chat', path: '/chat', builder: (context, state) => ChatScreen()),
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
