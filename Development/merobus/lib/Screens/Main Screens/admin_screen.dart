import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:merobus/Screens/Sub%20Screens/admin%20screens/user_detail.dart';
import 'package:merobus/models/all_users.dart'; // Import the model
import 'package:merobus/routes/routes.dart';
import '../../Components/AppColors.dart';
import 'package:http/http.dart' as http;

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  // Lists to store fetched user data
  List<User> _users = [];
  List<User> _requests = [];

  @override
  void initState() {
    super.initState();
    _getAllUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16.h),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Details Table
              Text(
                "User Details",
                style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16.h),
              _users.isEmpty
                  ? const Center(
                      child: Text(
                        "No user data available",
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : Table(
                      border: TableBorder.all(color: Colors.grey),
                      columnWidths: {
                        0: FlexColumnWidth(1.w), // ID
                        1: FlexColumnWidth(3.w), // Name
                        2: FlexColumnWidth(2.w), // Role
                      },
                      children: [
                        TableRow(
                          decoration:
                              const BoxDecoration(color: AppColors.primary),
                          children: [
                            tableTitle('ID'),
                            tableTitle('Name'),
                            tableTitle('Role'),
                          ],
                        ),
                        for (var user in _users)
                          TableRow(
                            children: [
                              tableCell(user.id.toString()),
                              tableCell(user.username ?? "N/A"),
                              tableCell(getUserRole(user.role ?? 0)),
                            ],
                          ),
                      ],
                    ),
              SizedBox(height: 32.h),

              // Requests Table
              Text(
                "Requests",
                style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16.h),
              _requests.isEmpty
                  ? const Center(
                      child: Text(
                        "No requests available",
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : Table(
                      border: TableBorder.all(color: Colors.grey),
                      columnWidths: {
                        0: FlexColumnWidth(1.5.w), // ID
                        1: FlexColumnWidth(3.w), // Name
                        2: FlexColumnWidth(3.w), // Role
                        3: FlexColumnWidth(2.w), // Status
                        4: FlexColumnWidth(2.w), // Action Button
                      },
                      children: [
                        TableRow(
                          decoration:
                              const BoxDecoration(color: AppColors.primary),
                          children: [
                            tableTitle('ID'),
                            tableTitle('Name'),
                            tableTitle('Role'),
                            tableTitle('Status'),
                            tableTitle('Action'),
                          ],
                        ),
                        for (var user in _requests)
                          TableRow(
                            children: [
                              tableCell(user.id.toString()),
                              tableCell(user.username ?? "N/A"),
                              tableCell(getUserRole(user.role ?? 0)),
                              tableCell(user.status ?? "N/A"),
                              Padding(
                                padding: EdgeInsets.all(4.h),
                                child: IconButton(
                                  icon: Icon(Icons.edit, color: AppColors.primary, size: 30.h,),
                                  onPressed: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => UserDetail(
                                                id: user.id!,
                                                name: user.username!)));
                                  },
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Padding tableTitle(String title) {
    return Padding(
      padding: EdgeInsets.all(4.h),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Padding tableCell(String text) {
    return Padding(
      padding: EdgeInsets.all(4.h),
      child: Text(text),
    );
  }

  // Helper method to display role based on user.role value
  String getUserRole(int role) {
    switch (role) {
      case 0:
        return "Admin";
      case 1:
        return "Passenger";
      case 2:
        return "Driver";
      default:
        return "Unknown";
    }
  }

  // Fetch user data from the API
  Future<void> _getAllUsers() async {
    try {
      final url = Uri.parse('${Routes.route}getAllUser');
      final response =
          await http.get(url, headers: {'Content-Type': 'application/json'});

      print(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = AllUsers.fromJson(json.decode(response.body));
          print(responseData.user);
        // Separate users and requests based on status
        setState(() {
          _users = responseData.user ?? [];
          _requests = _users.where((user) => user.status == "onHold").toList();
        });
      } else {
        // Handle non-successful response
        print("Failed to load users: ${response.statusCode}");
      }
    } catch (e) {
      // Handle error during the API call
      print("Error fetching users: $e");
    }
  }
}
