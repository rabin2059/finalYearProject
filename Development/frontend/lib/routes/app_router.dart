import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/user/Admin/admin%20home/presentation/admin_home_screen.dart';
import 'package:frontend/user/Admin/admin%20request/presentation/admin_request_screen.dart';
import 'package:frontend/user/Driver/add%20route/presentation/add_route_screen.dart';
import 'package:frontend/user/Driver/add%20vehicle/presentation/add_vehicle.dart';
import 'package:frontend/user/Driver/booking%20users%20details/presentation/booking_user_details.dart';
import 'package:frontend/user/Passenger/booking%20lists/presentation/booking_list_screen.dart';
import 'package:frontend/user/Passenger/book%20vehicle/presentation/booking_screen.dart';
import 'package:frontend/user/Passenger/bus%20details/presentation/bus_detail_screen.dart';
import 'package:frontend/user/authentication/forgot%20password/presentation/forgot.dart';
import 'package:frontend/user/authentication/otp/presentation/otp.dart';
import 'package:frontend/user/authentication/reset%20password/presentation/pass_change.dart';
import 'package:frontend/user/authentication/sign%20up/presentation/signup.dart';
import 'package:frontend/user/Passenger/user%20map/presentation/map_screen.dart';
import 'package:frontend/user/Passenger/payment/presentation/overview_screen.dart';
import 'package:frontend/user/Passenger/payment/presentation/payment_screen.dart';
import 'package:frontend/user/Passenger/profile/presentation/profile_screen.dart';
import 'package:frontend/user/Passenger/role%20change/presentation/role_change_screen.dart';
import 'package:frontend/user/Passenger/setting/presentation/setting_screen.dart';
import 'package:frontend/user/chat/chat%20lists/presentation/chat_driver_screen.dart';
import 'package:go_router/go_router.dart';

import '../core/shared_prefs_utils.dart';
import '../user/authentication/login/providers/auth_provider.dart';
import '../user/authentication/login/presentation/login_screen.dart';
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
      builder: (context, state) => FutureBuilder(
            future: checkTokenValidity(context),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError || snapshot.data == false) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  context.go('/login');
                });
                return const SizedBox.shrink();
              } else {
                return const SignUp();
              }
            },
          )),
  GoRoute(
      path: '/login',
      name: '/login',
      builder: (context, state) => FutureBuilder(
            future: checkTokenValidity(context),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError || snapshot.data == false) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  context.go('/login');
                });
                return const SizedBox.shrink();
              } else {
                return const LoginScreen();
              }
            },
          )),
  GoRoute(
      path: '/forgot',
      name: '/forgot',
      builder: (context, state) => FutureBuilder(
            future: checkTokenValidity(context),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError || snapshot.data == false) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  context.go('/login');
                });
                return const SizedBox.shrink();
              } else {
                return const Forgot();
              }
            },
          )),
  GoRoute(
    path: '/otp',
    name: '/otp',
    builder: (context, state) {
      final emails = state.pathParameters['email'] ?? '';
      return FutureBuilder(
        future: checkTokenValidity(context),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError || snapshot.data == false) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.go('/login');
            });
            return const SizedBox.shrink();
          } else {
            return OTP(email: emails);
          }
        },
      );
    },
  ),
  GoRoute(
    path: '/reset',
    name: '/reset',
    builder: (context, state) {
      final emails = state.pathParameters['email'] ?? '';
      return FutureBuilder(
        future: checkTokenValidity(context),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError || snapshot.data == false) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.go('/login');
            });
            return const SizedBox.shrink();
          } else {
            return PassChange(email: emails);
          }
        },
      );
    },
  ),
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
                  context.go('/login');
                });
                return const SizedBox.shrink();
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
                  context.go('/login');
                });
                return const SizedBox.shrink();
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
                  context.go('/login');
                });
                return const SizedBox.shrink();
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
              context.go('/login');
            });
            return const SizedBox.shrink();
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
                  context.go('/login');
                });
                return const SizedBox.shrink();
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
              context.go('/login');
            });
            return const SizedBox.shrink();
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
                  context.go('/login');
                });
                return const SizedBox.shrink();
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
                  context.go('/login');
                });
                return const SizedBox.shrink();
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
                  context.go('/login');
                });
                return const SizedBox.shrink();
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
              context.go('/login');
            });
            return const SizedBox.shrink();
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
                context.go('/login');
              });
              return const SizedBox.shrink();
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
                context.go('/login');
              });
              return const SizedBox.shrink();
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
              context.go('/login');
            });
            return const SizedBox.shrink();
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
              context.go('/login');
            });
            return const SizedBox.shrink();
          } else {
            return PaymentScreen(
                paymentUrl:
                    Uri.decodeComponent(paymentUrl)); // ✅ Pass decoded URL
          }
        },
      );
    },
  ),
]);

// 2) Define a little holder-class for type safety:

class ChatArgs {
  final int groupId;
  final String groupName;
  ChatArgs(this.groupId, this.groupName);
}
