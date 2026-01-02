import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  bool _obscurePassword = true;
final TextEditingController namecont =TextEditingController();
final TextEditingController emailcont =TextEditingController();
final TextEditingController phonenumbercont =TextEditingController();
final TextEditingController passwordcont =TextEditingController();


  @override
  void dispose() {
    namecont.dispose();
    emailcont.dispose();
    phonenumbercont.dispose();
    passwordcont.dispose();
    super.dispose();
  }

  Future<void> signupUser() async {
    final url = Uri.parse(
      "http://abohmed.atwebpages.com//store_user.php"
    );

    final body = {
      "name": namecont.text.trim(),
      "email": emailcont.text.trim(),
      "phonenumber": phonenumbercont.text.trim(),
      "password": passwordcont.text.trim(),
    };

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Account created successfully")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Network error: $e")),
      );
    }
  }










  static const Color primary = Color(0xFF19E619);
  static const Color backgroundLight = Color(0xFFF6F8F6);
  static const Color surfaceLight = Colors.white;
  static const Color textMain = Color(0xFF0E1B0E);
  static const Color textSub = Color(0xFF4E974E);
  static const Color borderColor = Color(0xFFD0E7D0);

  InputDecoration _inputDecoration({
    required String hint,
    Widget? suffix,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: textSub),
      filled: true,
      fillColor: surfaceLight,
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      suffixIcon: suffix ??
          Icon(
            icon,
            color: textSub,
            size: 22,
          ),
    );
  }

  TextStyle get titleStyle => const TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: textMain,
  );

  TextStyle get labelStyle => const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: textMain,
  );

  TextStyle get subtitleStyle => const TextStyle(
    fontSize: 16,
    color: textSub,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            children: [
              /// Header
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.chevron_left, size: 32),
                    ),
                  ),
                ),
              ),

              /// Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),

                      Text("Create Account", style: titleStyle),
                      const SizedBox(height: 8),
                      Text(
                        "Please fill in the details below to register as a Teacher.",
                        style: subtitleStyle,
                      ),

                      const SizedBox(height: 32),

                      /// Full Name
                      Text("Full Name", style: labelStyle),
                      const SizedBox(height: 8),
                      TextField(
                        decoration: _inputDecoration(
                          hint: "Ali ahmad",
                          icon: Icons.person_outline,

                        ),controller: namecont,
                      ),

                      const SizedBox(height: 20),

                      /// Email
                      Text("Email ", style: labelStyle),
                      const SizedBox(height: 8),
                      TextField(
                        keyboardType: TextInputType.emailAddress,
                        decoration: _inputDecoration(
                          hint: "@gmail.com",
                          icon: Icons.mail_outline,
                        ),controller: emailcont
                      ),

                      const SizedBox(height: 20),

                      /// Phone
                      Text("Phone Number", style: labelStyle),
                      const SizedBox(height: 8),
                      TextField(
                        keyboardType: TextInputType.phone,
                        decoration: _inputDecoration(
                          hint: " 70/000000",
                          icon: Icons.call_outlined,
                        ),controller: phonenumbercont
                      ),

                      const SizedBox(height: 20),

                      /// Password
                      Text("Password", style: labelStyle),
                      const SizedBox(height: 8),
                      TextField(
                        obscureText: _obscurePassword,
                        decoration: _inputDecoration(
                          hint: "Create a password",
                          icon: Icons.lock_outline,
                          suffix: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: textSub,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),controller: passwordcont
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Must be at least 8 characters",
                        style: TextStyle(fontSize: 12, color: textSub),
                      ),

                      const SizedBox(height: 32),

                      /// Sign Up
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {signupUser();},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: textMain,
                            elevation: 6,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            "Sign Up",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      /// Login
                      Center(
                        child: Text.rich(
                          TextSpan(
                            text: "Already a member? ",
                            style: const TextStyle(fontSize: 16),
                            children: const [
                              TextSpan(
                                text: "Log in",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
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
