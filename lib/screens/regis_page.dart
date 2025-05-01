import 'package:flutter/material.dart';
import 'login_page.dart';

void main() {
  runApp(const RegisPage());
}

class RegisPage extends StatelessWidget {
  const RegisPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: SignUpScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _agreeToTerms = false;
  bool _obscurePassword = true;

  final List<String> _roles = ['Admin', 'Pengguna'];
  String? _selectedRole;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Daftar",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  _buildTextField(label: "Name", hintText: "name"),
                  _buildTextField(label: "Username", hintText: "username"),
                  _buildTextField(
                    label: "Email",
                    hintText: "email@gmail.com",
                    keyboardType: TextInputType.emailAddress,
                  ),
                  _buildTextField(
                    label: "Password",
                    hintText: "Minimal 8 karakter",
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  _buildDropdownField(),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Checkbox(
                        value: _agreeToTerms,
                        onChanged: (value) {
                          setState(() {
                            _agreeToTerms = value ?? false;
                          });
                        },
                      ),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            text:
                                "Dengan mendaftar, saya setuju dengan persyaratan ",
                            style: const TextStyle(color: Colors.black),
                            children: [
                              TextSpan(
                                text: "Terms of Use",
                                style: const TextStyle(color: Colors.blue),
                              ),
                              const TextSpan(text: " & "),
                              TextSpan(
                                text: "Privacy Policy",
                                style: const TextStyle(color: Colors.blue),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0C1A3E),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        if (_formKey.currentState!.validate() &&
                            _agreeToTerms) {
                          // Handle Sign Up Logic
                        }
                      },
                      child: const Text("Daftar"),
                    ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                      );
                    },
                    child: const Text.rich(
                      TextSpan(
                        text: "Sudah memiliki akun? ",
                        children: [
                          TextSpan(
                            text: "Login",
                            style: TextStyle(color: Colors.blue),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Center(child: Text("OR")),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildSocialIcon("assets/google.png"),
                      const SizedBox(width: 16),
                      _buildSocialIcon("assets/facebook.png"),
                      const SizedBox(width: 16),
                      _buildSocialIcon("assets/apple.png"),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hintText,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 6),
        TextFormField(
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator:
              (value) => value == null || value.isEmpty ? "Required" : null,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Colors.grey),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  Widget _buildDropdownField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Role"),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _selectedRole,
          items:
              _roles.map((role) {
                return DropdownMenuItem(value: role, child: Text(role));
              }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedRole = value;
            });
          },
          decoration: InputDecoration(
            hintText: "Pilih role",
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
          ),
          validator: (value) => value == null ? "Please select a role" : null,
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  Widget _buildSocialIcon(String assetPath) {
    return InkWell(
      onTap: () {
        // Handle social login
      },
      child: CircleAvatar(
        radius: 20,
        backgroundColor: Colors.white,
        backgroundImage: AssetImage(assetPath),
      ),
    );
  }
}
