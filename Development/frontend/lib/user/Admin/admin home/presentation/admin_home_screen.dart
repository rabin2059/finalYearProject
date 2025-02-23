import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

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
              _buildUserTable(),
              SizedBox(height: 32.h),

              // Requests Table
              Text(
                "Requests",
                style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16.h),
              _buildRequestsTable(),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds User Details Table
  Widget _buildUserTable() {
    return Table(
      border: TableBorder.all(color: Colors.grey),
      columnWidths: {
        0: FlexColumnWidth(1.w), // ID
        1: FlexColumnWidth(3.w), // Name
        2: FlexColumnWidth(2.w), // Role
      },
      children: [
        TableRow(
          decoration: const BoxDecoration(color: Colors.blue),
          children: [
            _tableTitle('ID'),
            _tableTitle('Name'),
            _tableTitle('Role'),
          ],
        ),
        for (int i = 1; i <= 5; i++) // Dummy data
          TableRow(
            children: [
              _tableCell(i.toString()),
              _tableCell("User $i"),
              _tableCell("User"),
            ],
          ),
      ],
    );
  }

  /// Builds Requests Table
  Widget _buildRequestsTable() {
    return Table(
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
          decoration: const BoxDecoration(color: Colors.blue),
          children: [
            _tableTitle('ID'),
            _tableTitle('Name'),
            _tableTitle('Role'),
            _tableTitle('Status'),
            _tableTitle('Action'),
          ],
        ),
        for (int i = 1; i <= 3; i++) // Dummy data
          TableRow(
            children: [
              _tableCell(i.toString()),
              _tableCell("Requester $i"),
              _tableCell("Driver"),
              _tableCell("Pending"),
              Padding(
                padding: EdgeInsets.all(4.h),
                child: IconButton(
                  icon: Icon(Icons.edit, color: Colors.blue, size: 30.h),
                  onPressed: () {},
                ),
              ),
            ],
          ),
      ],
    );
  }

  Padding _tableTitle(String title) {
    return Padding(
      padding: EdgeInsets.all(4.h),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Padding _tableCell(String text) {
    return Padding(
      padding: EdgeInsets.all(4.h),
      child: Text(text),
    );
  }
}
