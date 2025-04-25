import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:merobus/get_started_screen.dart';
import 'package:merobus/user/Driver/add%20route/presentation/add_route_screen.dart';
import 'package:merobus/user/Driver/add%20vehicle/presentation/add_vehicle.dart';
import 'package:merobus/user/Driver/driver%20map/driver_map_screen.dart';
import 'package:merobus/user/Driver/home/presentation/driver_home_screen.dart';
import 'package:merobus/user/Driver/setting/presentation/driver_setting_screen.dart';
import 'package:merobus/user/Driver/vehicle%20details/presentation/view_vehicle_screen.dart';
import 'package:merobus/user/Passenger/profile/presentation/profile_screen.dart';
import 'package:merobus/user/Passenger/role%20change/presentation/role_change_screen.dart';
import 'package:merobus/user/navigations/driver_navigation.dart';
import 'package:merobus/user/navigations/navigation_screen.dart';

import '../user/Driver/booking lists/presentation/book_vehicle_list_screen.dart';
import '../user/Driver/booking users details/presentation/booking_user_details.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _sectionNavigatorKey = GlobalKey<NavigatorState>();

final _router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: "/",
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        name: '/',
        builder: (context, state) => const GetStartedScreen(),
      ),
      GoRoute(
        path: '/navigation',
        name: '/navigation',
        builder: (context, state) => const Navigation(),
      ),
      StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return DriverNavigation();
          },
          branches: [
            StatefulShellBranch(
                navigatorKey: _sectionNavigatorKey,
                routes: <RouteBase>[
                  GoRoute(
                    path: '/driverHome',
                    builder: (context, state) => const DriverHomeScreen(),
                    routes: <RouteBase>[
                      GoRoute(
                          path: '/map',
                          builder: (context, state) {
                            final id = int.parse(
                                    state.pathParameters['vehicleId'] ?? '') ??
                                0;
                            return DriverMapScreen(vehicleId: id);
                          })
                    ],
                  ),
                  GoRoute(
                    path: '/driverSettings',
                    builder: (context, state) => const DriverSettingScreen(),
                    routes: <RouteBase>[
                      GoRoute(
                          path: '/profile',
                          builder: (context, state) {
                            return ProfileScreen();
                          }),
                      GoRoute(
                          path: '/addVehicle',
                          builder: (context, state) {
                            return AddVehicle();
                          }),
                      GoRoute(
                          path: '/viewVehicle',
                          builder: (context, state) {
                            return ViewVehicleScreen();
                          }),
                      GoRoute(
                          path: '/addRoute/:id',
                          builder: (context, state) {
                            final id = int.tryParse(
                                    state.pathParameters['id'] ?? '0') ??
                                0;
                            return AddRouteScreen(
                              vehicleId: id,
                            );
                          }),
                      GoRoute(
                          path: '/bookingDetails/:bookId/:userId',
                          builder: (context, state) {
                            final bookId = int.parse(
                                state.pathParameters['bookId'] ?? '0');
                            final userId = int.parse(
                                state.pathParameters['userId'] ?? '0');
                            return BookingUserDetails(
                                bookId: bookId, userId: userId);
                          }),
                    ],
                  ),
                  GoRoute(
                    path: '/bookVehicleList',
                    builder: (context, state) => const BookVehicleListScreen(),
                    routes: <RouteBase>[
                      GoRoute(
                          path: '/profile',
                          builder: (context, state) {
                            return ProfileScreen();
                          }),
                      GoRoute(
                          path: '/roleChange',
                          builder: (context, state) {
                            return RoleChangeScreen();
                          }),
                    ],
                  ),
                ])
          ])
    ]);
