import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/user/authentication/login/providers/auth_provider.dart';
import 'package:frontend/user/chat/chat%20lists/provider/chat_list_state.dart';

import 'package:frontend/routes/app_router.dart';
import 'package:go_router/go_router.dart';
import '../provider/chat_list_provider.dart';

class ChatDriverScreen extends ConsumerStatefulWidget {
  const ChatDriverScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ChatDriverScreen> createState() => _ChatDriverScreenState();
}

class _ChatDriverScreenState extends ConsumerState<ChatDriverScreen> {
  @override
  void initState() {
    super.initState();
    final userId = ref.read(authProvider).userId;
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
      appBar: AppBar(
        title: const Text('My Chats'),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null && state.error!.isNotEmpty
              ? Center(child: Text('Error: ${state.error}'))
              : state.chatGroups == null || state.chatGroups!.isEmpty
                  ? const Center(child: Text('No chat groups found'))
                  : ListView.builder(
                      itemCount: state.chatGroups!.length,
                      itemBuilder: (context, index) {
                        final group = state.chatGroups![index];
                        final title = group.name ?? 'Chat #${group.id}';
                        final subtitle = group.vehicleInfo != null
                            ? 'Bus: ${group.vehicleInfo!.vehicleNo}'
                            : null;
                        return ListTile(
                          leading: const Icon(Icons.chat_bubble_outline),
                          title: Text(title),
                          subtitle:
                              subtitle != null ? Text(subtitle) : null,
                          trailing: group.messageCount != null
                              ? CircleAvatar(
                                  radius: 12,
                                  child: Text(
                                    group.messageCount.toString(),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                )
                              : null,
                          onTap: () {
                            final gid = group.id;
                            final gname = group.name ?? 'Chat #${group.id}';
                            context.pushNamed(
                              'chat',
                              extra: ChatArgs(gid!, gname),
                            );
                          },
                        );
                      },
                    ),
    );
  }
}