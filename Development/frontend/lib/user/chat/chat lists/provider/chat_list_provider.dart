import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants.dart';
import '../../../../data/services/chat_group_service.dart';
import 'chat_list_state.dart';

class ChatListNotifier extends StateNotifier<ChatListState> {
  final ChatGroupService chatGroupService;

  ChatListNotifier({required this.chatGroupService}) : super(ChatListState());

  Future<void> fetchChatList(int userId) async {
    try {
      state = state.copyWith(isLoading: true, error: '', chatGroups: []);

      final chatLists = await chatGroupService.getChatGroups(userId);

      state = state.copyWith(isLoading: false, chatGroups: chatLists);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final chatListProvider =
    StateNotifierProvider<ChatListNotifier, ChatListState>((ref) {
  final chatGroupService = ChatGroupService(baseUrl: apiBaseUrl);
  return ChatListNotifier(chatGroupService: chatGroupService);
});
