import 'package:frontend/data/models/chat_group_model.dart';

class ChatListState {
  final bool isLoading;
  final String? error;
  final List<ChatGroup>? chatGroups;

  ChatListState(
      {this.isLoading = false, this.error = "", this.chatGroups = const []});

  ChatListState copyWith(
      {bool? isLoading, String? error, List<ChatGroup>? chatGroups}) {
    return ChatListState(
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
        chatGroups: chatGroups ?? this.chatGroups);
  }

  factory ChatListState.initial(Map<String, dynamic>? response) {
    return ChatListState(
        isLoading: false, error: '', chatGroups: response?["chatGroups"] ?? []);
  }
}
