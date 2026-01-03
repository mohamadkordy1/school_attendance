import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../objects/user.dart';
import '../objects/classroom.dart';
import 'AttendancePage.dart';
import '../LoginPage.dart'; // ✅ make sure this path is correct
import 'package:google_fonts/google_fonts.dart';

class StudentHome extends StatefulWidget {
  final User user;
  const StudentHome({super.key, required this.user});

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  List<Classroom> myClasses = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchClasses();
  }

  Future<void> fetchClasses() async {
    final url = Uri.parse(
      "http://abohmed.atwebpages.com/get_student_classes.php?student_id=${widget.user.id}",
    );

    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        List data = jsonDecode(res.body);
        setState(() {
          myClasses = data.map((c) => Classroom.fromJson(c)).toList();
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching classes: $e");
      setState(() => isLoading = false);
    }
  }

  /// 🔴 LOGOUT HANDLER
  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
              );
            },
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FCF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FCF8),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          "Hi, ${widget.user.name}",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              onPressed: _logout,
              icon: const Icon(Icons.logout_rounded),
              color: const Color(0xFFDC2626),
              tooltip: "Logout",
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(color: Color(0xFF16A34A)),
      )
          : myClasses.isEmpty
          ? const Center(child: Text("No classes found"))
          : ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: myClasses.length,
        itemBuilder: (context, index) {
          final c = myClasses[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AttendancePage(
                    user: widget.user,
                    classroom: c,
                  ),
                ),
              );
            },
            child: _buildClassCard(
              c.name,
              c.startTime,
              c.teacherName,
              "Room TBD",
              const Color(0xFF16A34A),
            ),
          );
        },
      ),
    );
  }

  Widget _buildClassCard(
      String title,
      String time,
      String teacher,
      String room,
      Color sideColor,
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 80,
            decoration: BoxDecoration(
              color: sideColor,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(12),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        time,
                        style: TextStyle(
                          color: sideColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    "Teacher: $teacher",
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                  const Text(
                    "Click to view attendance",
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
