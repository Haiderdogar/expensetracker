import 'package:sqflite/sqflite.dart';

import '../constants/app_strings.dart';

class AppException implements Exception {
  AppException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

abstract final class ErrorHandler {
  static AppException from(Object error, [StackTrace? stackTrace]) {
    if (error is AppException) return error;

    if (error is DatabaseException) {
      return AppException(AppStrings.errorDatabase, cause: error);
    }

    return AppException(AppStrings.errorGeneric, cause: error);
  }

  static String message(Object error) => from(error).message;
}
