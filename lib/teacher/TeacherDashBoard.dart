import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'create_classroom.dart';
import 'classroom_details_page.dart';
import '../objects/user.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key, required this.user});
  final User user;

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  bool isLoading = true;
  List classrooms = [];

  @override
  void initState() {
    super.initState();
    fetchClassrooms();
  }

  Future<void> fetchClassrooms() async {
    try {
      final url = Uri.parse("http://abohmed.atwebpages.com/get_classrooms.php");

      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"teacher_id": widget.user.id}),
      );

      debugPrint("STATUS: ${res.statusCode}");


      if (res.statusCode != 200) throw Exception("Server error ${res.statusCode}");


      String cleanJson = res.body;
      int first = res.body.indexOf('[');
      int last = res.body.lastIndexOf(']');
      if (first != -1 && last != -1) {
        cleanJson = res.body.substring(first, last + 1);
      } else {

        first = res.body.indexOf('{');
        last = res.body.lastIndexOf('}');
        if(first != -1 && last != -1) cleanJson = res.body.substring(first, last + 1);
      }

      final decoded = jsonDecode(cleanJson);

      if (decoded is List) {
        setState(() {
          classrooms = decoded;
          isLoading = false;
        });
      } else if (decoded is Map) {

        setState(() {
          classrooms = [];
          isLoading = false;
        });

        if (decoded['error'] != null && decoded['error'] != "No classrooms found") {
          _showMsg(decoded['error']);
        }
      }
    } catch (e) {
      debugPrint("Error fetching: $e");
      setState(() => isLoading = false);
      _showMsg("Could not load classes");
    }
  }

  void _showMsg(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }


  void _openClassroom(Map<String, dynamic> classroomData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClassroomDetailsPage(classroom: classroomData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf6f8f6),
      appBar: AppBar(
        title: Text("Welcome, ${widget.user.name}"),
        backgroundColor: const Color(0xFF16A34A),
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF16A34A)))
          : classrooms.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.class_outlined, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text("No classrooms yet", style: TextStyle(color: Colors.grey)),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: classrooms.length,
        itemBuilder: (context, index) {
          final c = classrooms[index];


          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _openClassroom(c),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            c["name"] ?? "Class",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0f172a),
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.schedule, size: 16, color: Color(0xFF16A34A)),
                            const SizedBox(width: 6),
                            Text(
                              "${c["start_time"]} - ${c["finish_time"]}",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF16A34A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF16A34A),
        onPressed: () async {

          final bool? result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CreateClassroomPage(user: widget.user),
            ),
          );


          if (result == true) {
            fetchClassrooms();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}