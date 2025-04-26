import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:merobus/data/models/chat_group_model.dart';
import 'package:merobus/user/Driver/booking%20lists/presentation/book_vehicle_list_screen.dart';
import 'package:merobus/user/Driver/home/presentation/driver_home_screen.dart';
import 'package:merobus/user/Driver/setting/presentation/driver_setting_screen.dart';
import 'package:merobus/user/Driver/update%20route/presentation/route_update_screen.dart';

import '../core/shared_prefs_utils.dart';
import '../user/Driver/add route/presentation/add_route_screen.dart';
import '../user/Driver/add vehicle/presentation/add_vehicle.dart';
import '../user/Driver/booking users details/presentation/booking_user_details.dart';
import '../user/Driver/vehicle details/presentation/view_vehicle_screen.dart';
import '../user/Passenger/book vehicle/presentation/booking_screen.dart';
import '../user/Passenger/booking lists/presentation/booking_list_screen.dart';
import '../user/Passenger/bus details/presentation/bus_detail_screen.dart';
import '../user/Passenger/payment/presentation/overview_screen.dart';
import '../user/Passenger/payment/presentation/payment_screen.dart';
import '../user/Passenger/profile/presentation/profile_screen.dart';
import '../user/Passenger/role change/presentation/role_change_screen.dart';
import '../user/Passenger/user map/presentation/map_screen.dart';
import '../user/authentication/forgot password/presentation/forgot.dart';
import '../user/authentication/login/providers/auth_provider.dart';
import '../user/authentication/login/presentation/login_screen.dart';
import '../user/authentication/otp/presentation/otp.dart';
import '../user/authentication/reset password/presentation/pass_change.dart';
import '../user/authentication/sign up/presentation/signup.dart';
import '../user/chat/chat lists/presentation/chat_driver_screen.dart';
import '../user/chat/chatting screens/presentation/chat_screen.dart';
import '../user/navigations/navigation_screen.dart';
import '../get_started_screen.dart';

Future<bool> checkTokenValidity(BuildContext context) async {
  final tokenData = await SharedPrefsUtil.getToken();
  final token = (tokenData is Map ? tokenData["token"] : tokenData) as String;

  try {
    final parts = token.split('.');
    if (parts.length != 3) return false;
    final payload =
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
    final exp = jsonDecode(payload)['exp'];
    final expiryDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    return DateTime.now().isBefore(expiryDate);
  } catch (e) {
    return false;
  }
}

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
      path: '/forgot',
      name: '/forgot',
      builder: (context, state) => const Forgot()),
  GoRoute(
      path: '/bookVehicleList',
      name: '/bookVehicleList',
      builder: (context, state) => const BookVehicleListScreen()),
  GoRoute(
      path: '/driverHome',
      name: '/driverHome',
      builder: (context, state) => const DriverHomeScreen()),
  GoRoute(
      path: '/driverSettings',
      name: '/driverSettings',
      builder: (context, state) => const DriverSettingScreen()),
  GoRoute(
      path: '/otp',
      name: '/otp',
      builder: (context, state) {
        final emails = state.pathParameters['email'] ?? '';
        return OTP(email: emails);
      }),
  GoRoute(
      path: '/reset',
      name: '/reset',
      builder: (context, state) {
        final emails = state.pathParameters['email'] ?? '';
        return PassChange(email: emails);
      }),
  GoRoute(
      path: '/ChatGroup',
      name: '/ChatGroup',
      builder: (context, state) => ChatDriverScreen()),
  GoRoute(
      name: '/navigation',
      path: '/navigation',
      builder: (context, state) => Navigation()),
  GoRoute(
      name: '/addVehicle',
      path: '/addVehicle',
      builder: (context, state) => AddVehicle()),
  GoRoute(
    name: 'addRoute', //
    path: '/addRoute/:id', //
    builder: (context, state) {
      final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
      return AddRouteScreen(vehicleId: id);
    },
  ),
  GoRoute(
      name: '/profile',
      path: '/profile',
      builder: (context, state) => ProfileScreen()),
  GoRoute(
    path: '/chat',
    name: 'chat',
    builder: (context, state) {
      final args = state.extra as ChatArgs;
      return ChatScreen(groupId: args.groupId, groupName: args.groupName);
    },
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
      final busId = int.parse(state.pathParameters['id'] ?? '0');
      return BusDetailScreen(busId: busId);
    },
  ),
  GoRoute(
    name: '/routeUpdate',
    path: '/routeUpdate/:id',
    builder: (context, state) {
      final routeID = int.parse(state.pathParameters['id'] ?? '0');
      return RouteUpdateScreen(routeId: routeID);
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
      path: '/overview/:id',
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
    path: '/payment/:url/:pidx',
    builder: (context, state) {
      final String? paymentUrl = state.pathParameters['url'];
      final String? pidx = state.pathParameters['pidx'];
      if (paymentUrl == null || paymentUrl.isEmpty || pidx == null || pidx.isEmpty) {
        return Scaffold(
          body: Center(child: Text("Invalid Payment Parameters")),
        );
      }
      return PaymentScreen(
        paymentUrl: Uri.decodeComponent(paymentUrl),
        pidx: pidx,
      );
    },
  ),
  GoRoute(
      name: '/viewVehicle',
      path: '/viewVehicle',
      builder: (context, state) => ViewVehicleScreen()),
]);

class ChatArgs {
  final int groupId;
  final String groupName;
  ChatArgs(this.groupId, this.groupName);
}
