import 'package:flutter/material.dart';

void showSuccessPopup(
  BuildContext context,
  String message,
  VoidCallback onDone,
) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder:
        (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 64),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
  );

  Future.delayed(const Duration(seconds: 5), () {
    Navigator.of(context).pop();
    onDone();
  });
}

// Method baru untuk auto close success popup
void showAutoCloseSuccessPopup(
  BuildContext context,
  String message, {
  VoidCallback? onDone,
  int durationSeconds = 2,
}) {
  // Gunakan GlobalKey untuk menangani dialog context
  final GlobalKey<NavigatorState> dialogNavigatorKey =
      GlobalKey<NavigatorState>();

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      // Timer dimulai di sini agar context valid
      Future.delayed(Duration(seconds: durationSeconds), () {
        if (Navigator.of(dialogContext).canPop()) {
          Navigator.of(dialogContext).pop();
        }
      });

      return WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 64),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    },
  ).then((_) {
    // Callback ketika popup sudah ditutup
    if (onDone != null) {
      onDone();
    }
  });
}
