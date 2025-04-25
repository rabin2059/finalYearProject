import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants.dart';
import '../../admin home/provider/admin_provider.dart';

class AdminRequestScreen extends ConsumerStatefulWidget {
  const AdminRequestScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _AdminRequestScreenState();
}

class _AdminRequestScreenState extends ConsumerState<AdminRequestScreen> {
  bool _isRefreshing = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => fetchAllUser());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchAllUser() async {
    try {
      await ref.read(adminProvider.notifier).fetchAllUser();
    } catch (e) {
      print('Failed to fetch users: $e');
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _isRefreshing = true;
    });
    await fetchAllUser();
    setState(() {
      _isRefreshing = false;
    });
  }

  List<dynamic> _getFilteredUsers(List<dynamic> users) {
    return users.where((user) {
      return user.role?.toUpperCase() == 'USER' &&
          user.status?.toLowerCase() == 'onhold';
    }).toList();
  }

  // Get unique roles from users
  List<String> _getUniqueRoles(List<dynamic> users) {
    final roles = users
        .map((user) => user.role?.toString() ?? 'Unknown')
        .where((role) => role.toUpperCase() != 'ADMIN')
        .toSet()
        .toList();
    roles.sort();
    return ['All', ...roles];
  }

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminProvider);
    final allPendingUsers =
        adminState.users != null ? _getFilteredUsers(adminState.users!) : [];
    final searchedUsers = allPendingUsers.where((user) {
      final query = _searchQuery.toLowerCase();
      return (user.username?.toLowerCase().contains(query) ?? false) ||
          (user.email?.toLowerCase().contains(query) ?? false) ||
          (user.phone?.toLowerCase().contains(query) ?? false);
    }).toList();
    final uniqueRoles =
        adminState.users != null ? _getUniqueRoles(adminState.users!) : ['All'];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: adminState.isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search and filter bar
                Container(
                  color: Colors.white,
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
                    children: [
                      // Search bar
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search users...',
                            prefixIcon:
                                Icon(Icons.search, color: Colors.grey[600]),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        ),
                      ),
                      SizedBox(height: 12),

                      // Role filter chips
                    ],
                  ),
                ),

                // Stats summary
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _buildStatCard(
                          context,
                          Icons.people,
                          allPendingUsers.length.toString(),
                          'Total Requests',
                          Colors.blue),
                      SizedBox(width: 12),
                      _buildStatCard(
                          context,
                          Icons.person_outline,
                          searchedUsers.length.toString(),
                          'Filtered',
                          Colors.green),
                    ],
                  ),
                ),

                // User list
                Expanded(
                  child: searchedUsers.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _refreshData,
                          child: ListView.builder(
                            padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: searchedUsers.length,
                            itemBuilder: (context, index) {
                              final user = searchedUsers[index];
                              return _buildUserCard(user);
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatCard(BuildContext context, IconData icon, String value,
      String label, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(dynamic user) {
    // Determine role-based color
    Color roleColor;
    switch (user.role?.toLowerCase() ?? '') {
      case 'admin':
        roleColor = Colors.red;
        break;
      case 'driver':
        roleColor = Colors.blue;
        break;
      case 'passenger':
        roleColor = Colors.green;
        break;
      default:
        roleColor = Colors.grey;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // Navigate to user details page
            // context.pushNamed('/userDetails', pathParameters: {'userId': user.id.toString()});
          },
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // User avatar
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 60,
                    height: 60,
                    child: user.images != null
                        ? Image.network(
                            imageUrl + user.images!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildPlaceholderAvatar(user.username);
                            },
                          )
                        : _buildPlaceholderAvatar(user.username),
                  ),
                ),
                SizedBox(width: 16),

                // User details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              user.username ?? 'No name',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: roleColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              user.role ?? 'Unknown',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: roleColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.email_outlined,
                              size: 14, color: Colors.grey[600]),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              user.email ?? 'No email',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.phone_outlined,
                              size: 14, color: Colors.grey[600]),
                          SizedBox(width: 4),
                          Text(
                            user.phone ?? 'No phone',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () async {
                              final response = await http.put(
                                Uri.parse(
                                    '$apiBaseUrl/validDriverRole'),
                                headers: {'Content-Type': 'application/json'},
                                body: jsonEncode({
                                  'status': 'approved',
                                  'id': user.id,
                                }),
                              );

                              if (response.statusCode == 200) {
                                print('User approved successfully');
                                await fetchAllUser(); // Refresh the list
                              } else {
                                print('Failed to approve: ${response.body}');
                              }
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.green,
                            ),
                            child: Text('Approve'),
                          ),
                          SizedBox(width: 8),
                          TextButton(
                            onPressed: () async {
                              final response = await http.put(
                                Uri.parse(
                                    '$apiBaseUrl/validDriverRole'),
                                headers: {'Content-Type': 'application/json'},
                                body: jsonEncode({
                                  'status': 'decline',
                                  'id': user.id,
                                }),
                              );

                              if (response.statusCode == 200) {
                                print('User rejected successfully');
                                await fetchAllUser();
                              } else {
                                print('Failed to reject: ${response.body}');
                              }
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: Text('Reject'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderAvatar(String? username) {
    final initials = username != null && username.isNotEmpty
        ? username
            .split(' ')
            .map((part) => part.isNotEmpty ? part[0].toUpperCase() : '')
            .take(2)
            .join()
        : '?';

    return Container(
      color: Colors.blue.shade100,
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade800,
          ),
        ),
      ),
    );
  }

  void _showUserActions(BuildContext context, dynamic user) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // User info header
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: user.images != null
                              ? Image.network(
                                  imageUrl + user.images!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return _buildPlaceholderAvatar(
                                        user.username);
                                  },
                                )
                              : _buildPlaceholderAvatar(user.username),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.username ?? 'Unknown User',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              user.email ?? '',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Divider(height: 24),

                // Action buttons
                _buildActionButton(
                  icon: Icons.visibility,
                  label: 'View Profile',
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to user profile
                  },
                ),

                _buildActionButton(
                  icon: Icons.edit,
                  label: 'Edit User',
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to edit user screen
                  },
                ),

                _buildActionButton(
                  icon: Icons.block,
                  label: user.isBlocked ? 'Unblock User' : 'Block User',
                  color: user.isBlocked ? Colors.green : Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    // Implement block/unblock functionality
                  },
                ),

                _buildActionButton(
                  icon: Icons.delete_outline,
                  label: 'Delete User',
                  color: Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteConfirmation(context, user);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: color != null ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: onTap,
    );
  }

  void _showDeleteConfirmation(BuildContext context, dynamic user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete User'),
        content: Text(
            'Are you sure you want to delete ${user.username}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            onPressed: () {
              Navigator.pop(context);
              // Implement delete functionality
            },
            child: Text('DELETE'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_off,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No users found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try changing your search or filter'
                : 'Add users to get started',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
