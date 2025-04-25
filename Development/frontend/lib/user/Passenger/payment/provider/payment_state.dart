
import '../../../../data/models/book_model.dart';

class PaymentState {
  final bool isLoading;
  final String? errorMessage;
  final Book? book;

  PaymentState({
    this.isLoading = false,
    this.errorMessage,
    this.book,
  });

  PaymentState copyWith({
    bool? isLoading,
    String? errorMessage,
    Book? book,
  }) {
    return PaymentState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      book: book ?? this.book,
    );
  }

  factory PaymentState.initial(Map<String, dynamic>? response) {
    return PaymentState(
        isLoading: false,
        errorMessage: response?['error'] ?? '',
        book: response?['book']);
  }
}
