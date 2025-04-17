import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/user/Admin/admin%20home/presentation/admin_home_screen.dart';
import 'package:frontend/user/Admin/admin%20request/presentation/admin_request_screen.dart';
import 'package:frontend/user/Driver/add%20route/presentation/add_route_screen.dart';
import 'package:frontend/user/Driver/add%20vehicle/presentation/add_vehicle.dart';
import 'package:frontend/user/Driver/booking%20users%20details/presentation/booking_user_details.dart';
import 'package:frontend/user/Driver/chat/presentation/chat_driver_screen.dart';
import 'package:frontend/user/Driver/vehicle%20details/presentation/view_vehicle_screen.dart';
import 'package:frontend/user/Passenger/booking%20lists/presentation/booking_list_screen.dart';
import 'package:frontend/user/Passenger/book%20vehicle/presentation/booking_screen.dart';
import 'package:frontend/user/Passenger/bus%20details/presentation/bus_detail_screen.dart';
import 'package:frontend/user/authentication/sign%20up/presentation/signup.dart';
import 'package:frontend/user/chat/presentation/chat_screen.dart';
import 'package:frontend/user/Passenger/user%20map/presentation/map_screen.dart';
import 'package:frontend/user/Passenger/payment/presentation/overview_screen.dart';
import 'package:frontend/user/Passenger/payment/presentation/payment_screen.dart';
import 'package:frontend/user/Passenger/profile/presentation/profile_screen.dart';
import 'package:frontend/user/Passenger/role%20change/presentation/role_change_screen.dart';
import 'package:frontend/user/Passenger/setting/presentation/setting_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:frontend/routes/global.dart';

import '../user/authentication/login/providers/auth_provider.dart';
import '../user/authentication/login/presentation/login_screen.dart';
import '../user/navigations/navigation_screen.dart';
import '../get_started_screen.dart';

final goRouter = GoRouter(
  navigatorKey: navigatorKey,
  // initialLocation: '/',
  // redirect: (context, state) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final token = prefs.getString('token');

  //   final loggingIn =
  //       state.matchedLocation == '/login' || state.matchedLocation == '/signup';

  //   if (token == null || JwtDecoder.isExpired(token)) {
  //     if (!loggingIn) return '/login';
  //   } else {
  //     if (loggingIn) return '/navigation';
  //   }

  //   return null;
  // },
  routes: <RouteBase>[
    GoRoute(
        path: '/',
        name: '/',
        builder: (context, state) => const GetStartedScreen()),
    GoRoute(
        path: '/signup',
        name: '/signup',
        builder: (context, state) => const SignUp()),
    GoRoute(
        path: '/Chat',
        name: '/Chat',
        builder: (context, state) => const DriverChatGroupsScreen()),
    GoRoute(
        path: '/viewVehicle',
        name: '/viewVehicle',
        builder: (context, state) => const ViewVehicleScreen()),
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
      path: '/chat/:groupId/:groupName',
      name: 'chat',
      builder: (context, state) => ChatScreen(
        groupId: int.parse(state.pathParameters['groupId']!),
        groupName: state.pathParameters['groupName']!,
      ),
    ),
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
      name: '/busDetail',
      path: '/busDetail/:id',
      builder: (context, state) {
        final busId =
            int.parse(state.pathParameters['id'] ?? '0'); // ✅ Extract ID
        return BusDetailScreen(busId: busId);
      },
    ),
    GoRoute(
        name: '/book',
        path: '/book/:id',
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
      name: '/bookingDetails',
      path: '/bookingDetails/:bookId/:userId',
      builder: (context, state) {
        final bookId = int.parse(state.pathParameters['bookId'] ?? '0');
        final userId = int.parse(state.pathParameters['userId'] ?? '0');
        return BookingUserDetails(bookId: bookId, userId: userId);
      },
    ),
    GoRoute(
      name: '/payment',
      path: '/payment/:url',
      builder: (context, state) {
        final String? paymentUrl = state.pathParameters['url'];

        if (paymentUrl == null || paymentUrl.isEmpty) {
          return Scaffold(
            body: Center(child: Text("Invalid Payment URL")),
          );
        }

        return PaymentScreen(paymentUrl: Uri.decodeComponent(paymentUrl));
      },
    ),
  ],
);
