class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.code});

  final String message;
  final int? statusCode;
  final String? code;

  @override
  String toString() => message;
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException([super.message = 'Session expired. Please log in again.'])
      : super(statusCode: 401);
}

class ForbiddenException extends ApiException {
  const ForbiddenException([super.message = 'Access denied. You do not have permission for this action.'])
      : super(statusCode: 403);
}

class NotFoundException extends ApiException {
  const NotFoundException([super.message = 'The requested resource was not found.'])
      : super(statusCode: 404);
}

class NetworkException extends ApiException {
  const NetworkException([super.message = 'Unable to connect to Navixa server. Please check your network.']);
}
