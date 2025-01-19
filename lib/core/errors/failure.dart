// lib/core/errors/failures.dart

import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  const Failure();

  @override
  List<Object> get props => [];
}

class ServerFailure extends Failure {
  final String? message;

  const ServerFailure([this.message]);

  @override
  List<Object> get props => [message ?? ''];
}

class CacheFailure extends Failure {
  final String? message;

  const CacheFailure([this.message]);

  @override
  List<Object> get props => [message ?? ''];
}

class ConnectionFailure extends Failure {
  const ConnectionFailure();
}

class ValidationFailure extends Failure {
  final String message;

  const ValidationFailure(this.message);

  @override
  List<Object> get props => [message];
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}
