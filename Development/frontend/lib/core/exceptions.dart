class CustomException implements Exception {
  final String message;
  
  CustomException(this.message);

  @override
  String toString() => "CustomException: $message";
}

class NetworkException extends CustomException {
  NetworkException(String message) : super(message);
}

class DatabaseException extends CustomException {
  DatabaseException(String message) : super(message);
}

class AuthenticationException extends CustomException {
  AuthenticationException(String message) : super(message);
}

