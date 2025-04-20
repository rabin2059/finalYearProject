import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; 
import 'package:merobus/user/Admin/admin%20home/provider/admin_provider.dart';
import '../../../../core/constants.dart';

class AdminHomeScreen extends ConsumerStatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _AdminHomeScreenState();
}

class _AdminHomeScreenState extends ConsumerState<AdminHomeScreen> {
  bool _isRefreshing = false;
  String _filterRole = 'All';
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
      if (user.role?.toUpperCase() == 'ADMIN') return false;
      // First apply role filter
      if (_filterRole != 'All' && user.role != _filterRole) {
        return false;
      }

      // Then apply search query if it exists
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return (user.username?.toLowerCase().contains(query) ?? false) ||
            (user.email?.toLowerCase().contains(query) ?? false) ||
            (user.phone?.toLowerCase().contains(query) ?? false);
      }

      return true;
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
    final filteredUsers =
        adminState.users != null ? _getFilteredUsers(adminState.users!) : [];
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
                      SizedBox(
                        height: 40,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: uniqueRoles.length,
                          itemBuilder: (context, index) {
                            final role = uniqueRoles[index];
                            final isSelected = role == _filterRole;

                            return Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(role),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    _filterRole = role;
                                  });
                                },
                                backgroundColor: Colors.white,
                                selectedColor: Colors.blue[100],
                                checkmarkColor: Colors.blue[800],
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? Colors.blue[800]
                                      : Colors.black87,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
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
                          (adminState.users
                                  ?.where((user) => user.role?.toUpperCase() != 'ADMIN')
                                  .length
                                  .toString() ??
                              '0'),
                          'Total Users',
                          Colors.blue),
                      SizedBox(width: 12),
                      _buildStatCard(
                          context,
                          Icons.person_outline,
                          filteredUsers.length.toString(),
                          'Filtered',
                          Colors.green),
                    ],
                  ),
                ),

                // User list
                Expanded(
                  child: filteredUsers.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _refreshData,
                          child: ListView.builder(
                            padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: filteredUsers.length,
                            itemBuilder: (context, index) {
                              final user = filteredUsers[index];
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
            _searchQuery.isNotEmpty || _filterRole != 'All'
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
