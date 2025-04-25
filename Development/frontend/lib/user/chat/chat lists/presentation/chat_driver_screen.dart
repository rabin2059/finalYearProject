import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../components/AppColors.dart';
import '../../../../routes/app_router.dart';
import '../../../authentication/login/providers/auth_provider.dart';
import '../provider/chat_list_provider.dart';

class ChatDriverScreen extends ConsumerStatefulWidget {
  const ChatDriverScreen({super.key});

  @override
  ConsumerState<ChatDriverScreen> createState() => _ChatDriverScreenState();
}

class _ChatDriverScreenState extends ConsumerState<ChatDriverScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final userId = ref.read(authProvider).userId;
      if (userId != null) {
        ref.read(chatListProvider.notifier).fetchChatList(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        title: const Text(
          'My Chats',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              // Add search functionality
            },
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            )
          : state.error != null && state.error!.isNotEmpty
              ? _buildErrorState(state.error!)
              : state.chatGroups == null || state.chatGroups!.isEmpty
                  ? _buildEmptyState()
                  : _buildChatList(state),
      // FloatingActionButton removed
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 60,
            color: AppColors.accent,
          ),
          const SizedBox(height: 16),
          Text(
            'Error: $error',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () {
              final userId = ref.read(authProvider).userId;
              if (userId != null) {
                ref.read(chatListProvider.notifier).fetchChatList(userId);
              }
            },
            child: const Text('Try Again'),
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
          Image.asset(
            'assets/images/empty_chat.png', // Add this asset or replace with another widget
            height: 120,
            width: 120,
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: AppColors.primary.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No chats yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation to connect with others',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Start New Chat'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () {
              // Start new chat logic
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChatList(dynamic state) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: state.chatGroups!.length,
      separatorBuilder: (context, index) =>
          const Divider(height: 1, indent: 70),
      itemBuilder: (context, index) {
        final group = state.chatGroups![index];
        final title = group.name ?? 'Chat #${group.id}';
        final subtitle = group.vehicleInfo != null
            ? 'Bus: ${group.vehicleInfo!.vehicleNo}'
            : 'No vehicle information';

        // Random generation of last message time for demo purposes
        // In a real app, this would come from your data model
        final lastMessageTime = DateTime.now().subtract(
          Duration(minutes: (index * 27) % 300),
        );
        final timeString = _formatTime(lastMessageTime);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          elevation: 0.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: _getAvatarColor(index),
              radius: 24,
              child: Text(
                title.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            title: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                subtitle,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  timeString,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                // message count indicator removed
              ],
            ),
            onTap: () {
              final gid = group.id;
              final gname = group.name ?? 'Chat #${group.id}';
              context.pushNamed(
                'chat',
                extra: ChatArgs(gid!, gname),
              );
            },
          ),
        );
      },
    );
  }

  Color _getAvatarColor(int index) {
    final colors = [
      AppColors.primary,
      AppColors.purple,
      AppColors.accent,
      AppColors.buttonColor,
    ];
    return colors[index % colors.length];
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    if (now.day == time.day &&
        now.month == time.month &&
        now.year == time.year) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      return '${time.day}/${time.month}';
    }
  }
}
