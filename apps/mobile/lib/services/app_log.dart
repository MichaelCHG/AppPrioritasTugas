import 'dart:developer' as developer;

const _loggerName = 'prioritas_tugas';

void logAppInfo(String message) {
  developer.log(message, name: _loggerName, level: 800);
}

void logAppWarning(String message) {
  developer.log(message, name: _loggerName, level: 900);
}

void logAppError(String message, Object error, StackTrace stackTrace) {
  developer.log(
    message,
    name: _loggerName,
    level: 1000,
    error: error,
    stackTrace: stackTrace,
  );
}
