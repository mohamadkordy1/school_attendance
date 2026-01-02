import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'signupPage.dart';
import 'teacher/TeacherDashBoard.dart';
import 'Student/StudentHome.dart';
import 'objects/user.dart';
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool hidePassword = true;

  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();

  static const Color primary = Color(0xFF16A34A);

  @override
  void dispose() {
    emailCtrl.dispose();
    passwordCtrl.dispose();
    super.dispose();
  }

  InputDecoration input(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  /// 🔐 LOGIN API
  Future<void> login() async {
    final url = Uri.parse(
      "http://abohmed.atwebpages.com/login_user.php",
    );

    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": emailCtrl.text.trim(),
        "password": passwordCtrl.text.trim(),
      }),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);

      User user=User(jsonDecode(res.body)["name"], jsonDecode(res.body)["email"], jsonDecode(res.body)["phonenumber"], jsonDecode(res.body)["role"], jsonDecode(res.body)["user_id"]);

      if (user.role == "student") {

        Navigator.of(context).push(MaterialPageRoute(builder: (context) =>  StudentHome( user: user,),));





    } else if (user.role == "teacher") {

        Navigator.of(context).push(MaterialPageRoute(builder: (context) =>  TeacherDashboard(user: user,),));

    }

    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.body)),
      );
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.school, size: 60, color: primary),
                const SizedBox(height: 12),
                const Text(
                  "Classroom Connect",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),

                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: input("Email", Icons.mail),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: passwordCtrl,
                  obscureText: hidePassword,
                  decoration: input("Password", Icons.lock).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        hidePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () =>
                          setState(() => hidePassword = !hidePassword),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                    ),
                    onPressed: login,
                    child: const Text("Log In"),
                  ),
                ),

                const SizedBox(height: 16),

                /// 👉 SIGN UP NAVIGATION ONLY
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? "),
                    TextButton(
                      onPressed: () {  Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SignupPage(),));

                      },
                      child: const Text(
                        "Sign up",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
