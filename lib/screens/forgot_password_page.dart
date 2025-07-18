import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'otp_verification_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
  }

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();

    if (email.isEmpty || !_isValidEmail(email)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Email tidak valid')));
      return;
    }

    setState(() => _isLoading = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final res = await ApiService.sendOtp(email);

      if (!mounted) return;
      Navigator.pop(context); // tutup loading
      setState(() => _isLoading = false);

      if (res['success']) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OtpVerificationPage(email: email)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Gagal kirim OTP')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Terjadi error: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lupa Password')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: "Email",
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _sendOtp,
              child: const Text("Kirim OTP"),
            ),
          ],
        ),
      ),
    );
  }
}
