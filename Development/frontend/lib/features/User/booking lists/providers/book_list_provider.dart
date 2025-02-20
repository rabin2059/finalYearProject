import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/data/services/book_service.dart';
import 'package:frontend/features/User/booking%20lists/providers/book_list_state.dart';

import '../../../../core/constants.dart';

class BookListNotifier extends StateNotifier<BookListState> {
  final BookService bookService;

  BookListNotifier({required this.bookService}) : super(BookListState());

  Future<void> fetchSingleBook(int userId) async {
    try {
      state = state.copyWith(loading: true, books: null, errorMessage: '');
      final book = await bookService.fetchBookings(userId);
      state = state.copyWith(loading: false, books: book, errorMessage: '');
    } catch (e) {
      state = state.copyWith(loading: false, errorMessage: e.toString());
    }
  }
}

final bookListProvider =
    StateNotifierProvider<BookListNotifier, BookListState>((ref) {
  final bookService = BookService(baseUrl: apiBaseUrl);
  return BookListNotifier(bookService: bookService);
});
