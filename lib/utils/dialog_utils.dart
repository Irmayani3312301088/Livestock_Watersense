import 'package:flutter/material.dart';

void showSuccessPopup(
  BuildContext context,
  String message,
  VoidCallback onDone,
) {
  // Tampilkan dialog
  showDialog(
    context: context,
    barrierDismissible: false,
    builder:
        (_) => AlertDialog(
          backgroundColor: Colors.white,
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

  // Delay 5 detik sebelum menutup
  Future.delayed(const Duration(seconds: 5), () {
    // Gunakan SchedulerBinding agar dialogContext tetap aman
    if (context.mounted) {
      try {
        Navigator.of(context, rootNavigator: true).pop();
        onDone();
      } catch (e) {
        debugPrint('Error closing dialog: $e');
      }
    }
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
          backgroundColor: Colors.white,
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

void showDeletePhotoSuccessPopup(BuildContext context, {VoidCallback? onDone}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      //  Tutup popup otomatis setelah 2 detik
      Future.delayed(const Duration(seconds: 2), () {
        if (Navigator.of(dialogContext).canPop()) {
          Navigator.of(dialogContext).pop();
          if (onDone != null) onDone();
        }
      });

      return AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.delete_forever, color: Colors.red, size: 64),
            SizedBox(height: 16),
            Text(
              'Foto profil berhasil dihapus',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    },
  );
}

void showUserDeletedPopup(BuildContext context, {VoidCallback? onDone}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      Future.delayed(const Duration(seconds: 2), () {
        if (Navigator.of(dialogContext).canPop()) {
          Navigator.of(dialogContext).pop();
          if (onDone != null) onDone();
        }
      });

      return AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_remove, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Pengguna berhasil\ndihapus',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    },
  );
}

void showAllNotificationDeletedPopup(
  BuildContext context, {
  VoidCallback? onDone,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      Future.delayed(const Duration(seconds: 2), () {
        if (Navigator.of(dialogContext).canPop()) {
          Navigator.of(dialogContext).pop();
          if (onDone != null) onDone();
        }
      });

      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.notifications_off, color: Colors.red, size: 64),
            SizedBox(height: 16),
            Text(
              'Semua notifikasi berhasil\ndihapus',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    },
  );
}

void showSuccessDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    builder:
        (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Berhasil', style: TextStyle(color: Colors.green)),
            ],
          ),
          content: Text(message, style: const TextStyle(fontSize: 16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK', style: TextStyle(color: Colors.green)),
            ),
          ],
        ),
  );
}

void showErrorDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    builder:
        (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: const [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Text('Gagal', style: TextStyle(color: Colors.red)),
            ],
          ),
          content: Text(message, style: const TextStyle(fontSize: 16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Tutup', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
  );
}
