import 'package:flutter/material.dart';
import '../services/api_service.dart';

class OtpVerificationPage extends StatefulWidget {
  final String email;
  const OtpVerificationPage({super.key, required this.email});

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController otpController = TextEditingController();
  final TextEditingController passController = TextEditingController();
  bool _obscurePassword = true;

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    final otp = otpController.text.trim();
    final newPass = passController.text.trim();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final res = await ApiService.resetPasswordWithOtp(
        widget.email,
        otp,
        newPass,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          if (mounted) Navigator.pop(context); // tutup loading
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Timeout: Server tidak merespon')),
            );
          }
          return {'success': false, 'message': 'Timeout'};
        },
      );

      if (!mounted) return;
      Navigator.pop(context); // tutup loading

      if (res['success']) {
        otpController.clear();
        passController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password berhasil direset')),
        );

        Navigator.popUntil(context, (route) => route.isFirst);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Gagal reset password')),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Verifikasi OTP")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "OTP telah dikirim ke email:",
                style: theme.textTheme.bodyMedium,
              ),
              Text(
                widget.email,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // OTP Field
              TextFormField(
                controller: otpController,
                keyboardType: TextInputType.number,
                maxLength: 6, // <- Ubah sesuai OTP backend kamu
                decoration: const InputDecoration(
                  labelText: "Kode OTP",
                  prefixIcon: Icon(Icons.security),
                ),
                validator: (value) {
                  if (value == null || value.trim().length != 6) {
                    return "Kode OTP harus 6 digit";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Password Baru
              TextFormField(
                controller: passController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: "Password Baru",
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.length < 8) {
                    return "Password minimal 8 karakter";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 30),

              // Tombol Submit
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text("Reset Password"),
                  onPressed: _resetPassword,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
