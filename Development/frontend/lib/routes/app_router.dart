import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
      builder: (context, state) => FutureBuilder(
            future: checkTokenValidity(context),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError || snapshot.data == false) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) context.go('/login');
                });
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              } else {
                return const ChatDriverScreen();
              }
            },
          )),
  GoRoute(
      name: '/navigation',
      path: '/navigation',
      builder: (context, state) => FutureBuilder(
            future: checkTokenValidity(context),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError || snapshot.data == false) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) context.go('/login');
                });
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              } else {
                return Navigation();
              }
            },
          )),
  GoRoute(
      name: '/addVehicle',
      path: '/addVehicle',
      builder: (context, state) => FutureBuilder(
            future: checkTokenValidity(context),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError || snapshot.data == false) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) context.go('/login');
                });
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              } else {
                return AddVehicle();
              }
            },
          )),
  GoRoute(
    name: 'addRoute', //
    path: '/addRoute/:id', //
    builder: (context, state) {
      final id = int.tryParse(state.pathParameters['id'] ?? '0') ??
          0; // ✅ Extract ID safely
      return FutureBuilder(
        future: checkTokenValidity(context),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError || snapshot.data == false) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) context.go('/login');
            });
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else {
            return AddRouteScreen(vehicleId: id);
          }
        },
      );
    },
  ),
  GoRoute(
      name: '/profile',
      path: '/profile',
      builder: (context, state) => FutureBuilder(
            future: checkTokenValidity(context),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError || snapshot.data == false) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) context.go('/login');
                });
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              } else {
                return ProfileScreen();
              }
            },
          )),
  GoRoute(
    path: '/chat',
    name: 'chat',
    builder: (context, state) {
      // pull out whatever you passed in `extra`
      final args = state.extra as ChatArgs;
      return FutureBuilder(
        future: checkTokenValidity(context),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError || snapshot.data == false) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) context.go('/login');
            });
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else {
            return ChatScreen(
              groupId: args.groupId,
              groupName: args.groupName,
            );
          }
        },
      );
    },
  ),
  GoRoute(
      name: '/roleChange',
      path: '/roleChange',
      builder: (context, state) => FutureBuilder(
            future: checkTokenValidity(context),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError || snapshot.data == false) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) context.go('/login');
                });
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              } else {
                return RoleChangeScreen();
              }
            },
          )),
  GoRoute(
      name: '/bookings',
      path: '/bookings',
      builder: (context, state) => FutureBuilder(
            future: checkTokenValidity(context),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError || snapshot.data == false) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) context.go('/login');
                });
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              } else {
                return BookingListScreen();
              }
            },
          )),
  GoRoute(
      name: '/map',
      path: '/map',
      builder: (context, state) => FutureBuilder(
            future: checkTokenValidity(context),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError || snapshot.data == false) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) context.go('/login');
                });
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              } else {
                return MapScreens();
              }
            },
          )),
  GoRoute(
    name: '/busDetail', // ✅ Ensure name matches navigation call
    path: '/busDetail/:id', // ✅ Accepts a dynamic ID
    builder: (context, state) {
      final busId =
          int.parse(state.pathParameters['id'] ?? '0'); // ✅ Extract ID
      return FutureBuilder(
        future: checkTokenValidity(context),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError || snapshot.data == false) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) context.go('/login');
            });
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else {
            return BusDetailScreen(busId: busId);
          }
        },
      );
    },
  ),
  GoRoute(
      name: '/book',
      path: '/book/:id',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id'] ?? '0');
        return FutureBuilder(
          future: checkTokenValidity(context),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError || snapshot.data == false) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) context.go('/login');
              });
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            } else {
              return BookingScreen(busId: id);
            }
          },
        );
      }),
  GoRoute(
      name: '/overview',
      path: '/overview/:id', // ✅ Accepts a dynamic ID
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id'] ?? '0');
        return FutureBuilder(
          future: checkTokenValidity(context),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError || snapshot.data == false) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) context.go('/login');
              });
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            } else {
              return OverviewScreen(bookId: id);
            }
          },
        );
      }),
  GoRoute(
    name: '/bookingDetails',
    path: '/bookingDetails/:bookId/:userId',
    builder: (context, state) {
      final bookId = int.parse(state.pathParameters['bookId'] ?? '0');
      final userId = int.parse(state.pathParameters['userId'] ?? '0');
      return FutureBuilder(
        future: checkTokenValidity(context),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError || snapshot.data == false) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) context.go('/login');
            });
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else {
            return BookingUserDetails(bookId: bookId, userId: userId);
          }
        },
      );
    },
  ),
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

      return FutureBuilder(
        future: checkTokenValidity(context),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError || snapshot.data == false) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) context.go('/login');
            });
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else {
            return PaymentScreen(
                paymentUrl:
                    Uri.decodeComponent(paymentUrl)); // ✅ Pass decoded URL
          }
        },
      );
    },
  ),
  GoRoute(
    name: '/viewVehicle',
    path: '/viewVehicle',
    builder: (context, state) => FutureBuilder(
      future: checkTokenValidity(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError || snapshot.data == false) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/login');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else {
          return ViewVehicleScreen(); // Ensure you have this screen implemented and imported
        }
      },
    ),
  ),
]);

// 2) Define a little holder-class for type safety:

class ChatArgs {
  final int groupId;
  final String groupName;
  ChatArgs(this.groupId, this.groupName);
}
