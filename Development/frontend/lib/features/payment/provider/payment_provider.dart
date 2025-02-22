import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/data/services/book_service.dart';

import '../../../core/constants.dart';
import 'payment_state.dart';

class PaymentNotifier extends StateNotifier<PaymentState> {
  final BookService bookService;

  PaymentNotifier({required this.bookService}) : super(PaymentState());

  Future<void> fetchBook(int bookId) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: '');
      final book = await bookService.getBook(bookId);
      state = state.copyWith(isLoading: false, book: book, errorMessage: '');
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final bookProvider =
    StateNotifierProvider<PaymentNotifier, PaymentState>((ref) {
  final bookService = BookService(baseUrl: apiBaseUrl);
  return PaymentNotifier(bookService: bookService);
});
