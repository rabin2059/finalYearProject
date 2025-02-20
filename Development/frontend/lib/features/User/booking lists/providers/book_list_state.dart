import 'package:frontend/data/models/book_list_model.dart';

class BookListState {
  final bool loading;
  final String errorMessage;
  final Booking? books;

  BookListState({
    this.loading = false,
    this.errorMessage = '',
    this.books,
  });

  BookListState copyWith(
      {bool? loading, String? errorMessage, Booking? books}) {
    return BookListState(
      loading: loading ?? this.loading,
      errorMessage: errorMessage ?? this.errorMessage,
      books: books ?? this.books,
    );
  }

  factory BookListState.initial(Map<String, dynamic>? response) {
    return BookListState(
        loading: false,
        errorMessage: response?['error'] ?? '',
        books: response?['booking']);
  }
}
