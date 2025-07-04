import 'package:flutter/material.dart';

/// Manages snackbar display with consistent styling and behavior
class SnackBars {
  static void _hideCurrentSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  static void _showSnackBar(
    BuildContext context, {
    required String message,
    Color backgroundColor = Colors.black87,
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    // Hide any existing snackbar before showing new one
    _hideCurrentSnackBar(context);

    final snackBar = SnackBar(
      content: Text(message, style: const TextStyle(color: Colors.white)),
      backgroundColor: backgroundColor,
      duration: duration,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(2),
      dismissDirection: DismissDirection.horizontal,
      // Add dismiss action by default if no other action is provided
      action:
          action ??
          SnackBarAction(
            label: 'Dismiss',
            textColor: Colors.white,
            onPressed: () => _hideCurrentSnackBar(context),
          ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// Shows an error snackbar with red background
  static void error(BuildContext context, String message) {
    _showSnackBar(
      context,
      message: message,
      backgroundColor: Colors.red.shade900,
    );
  }

  /// Shows a success snackbar with green background
  static void success(BuildContext context, String message) {
    _showSnackBar(
      context,
      message: message,
      backgroundColor: Colors.green.shade900,
    );
  }

  /// Shows an info snackbar with blue background
  static void info(BuildContext context, String message) {
    _showSnackBar(
      context,
      message: message,
      backgroundColor: Colors.blue.shade900,
    );
  }

  /// Shows a warning snackbar with orange background
  static void warning(BuildContext context, String message) {
    _showSnackBar(
      context,
      message: message,
      backgroundColor: Colors.orange.shade900,
    );
  }

  /// Shows a retry snackbar with action button
  static void retry(
    BuildContext context,
    String message,
    VoidCallback onRetry,
  ) {
    _showSnackBar(
      context,
      message: message,
      backgroundColor: Colors.red.shade900,
      action: SnackBarAction(
        label: 'Retry',
        textColor: Colors.white,
        onPressed: () {
          _hideCurrentSnackBar(context);
          onRetry();
        },
      ),
    );
  }

  /// Shows a loading snackbar with infinite duration
  static void loading(BuildContext context, String message) {
    _showSnackBar(
      context,
      message: message,
      duration: const Duration(days: 1), // Effectively infinite
      action: null, // No dismiss button for loading state
    );
  }
}
