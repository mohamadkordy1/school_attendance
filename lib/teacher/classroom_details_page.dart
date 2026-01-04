import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'daily_attendance_page.dart';
import 'enroll_student_page.dart';
import 'attendance_date_page.dart';
class ClassroomDetailsPage extends StatefulWidget {
  final Map<String, dynamic> classroom;

  const ClassroomDetailsPage({super.key, required this.classroom});

  @override
  State<ClassroomDetailsPage> createState() => _ClassroomDetailsPageState();
}

class _ClassroomDetailsPageState extends State<ClassroomDetailsPage> {

  List students = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchStudents();
  }

  Future<void> deleteStudent(int studentId) async {
    final url = Uri.parse(
      "//abohmed.atwebpages.com/delete_student_from_classroom.php",
    );

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          "classroom_id": widget.classroom['id'],
          "student_id": studentId,
        }),
      );

      debugPrint("STATUS CODE: ${response.statusCode}");
      debugPrint("RAW RESPONSE: ${response.body}");

      final data = jsonDecode(response.body);

      if (data["success"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Student removed")),
        );
        fetchStudents();
      } else {
        debugPrint("SERVER ERROR: ${data["message"]}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"])),
        );
      }
    } catch (e) {
      debugPrint("DELETE ERROR: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Something went wrong")),
      );
    }
  }

  Future<void> fetchStudents() async {
    try {
      final url = Uri.parse("//abohmed.atwebpages.com/get_classroom_students.php");

      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "classroom_id": widget.classroom['id'],
        }),
      );

      String rawBody = res.body.trim();

      int startIndex = rawBody.indexOf('[');
      int endIndex = rawBody.lastIndexOf(']');

      if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {

        String cleanJson = rawBody.substring(startIndex, endIndex + 1);

        try {
          final data = jsonDecode(cleanJson);

          setState(() {
            students = data;
            isLoading = false;
          });
          debugPrint("Successfully parsed ${students.length} students.");
        } catch (e) {

          setState(() => isLoading = false);
          debugPrint("JSON Decode Error on Cleaned String: $e");
        }
      } else {

        setState(() {
          students = [];
          isLoading = false;
        });

        try {
          final errorCheck = jsonDecode(rawBody.substring(rawBody.indexOf('{'), rawBody.lastIndexOf('}') + 1));
          if(errorCheck['error'] != null) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Server Error: ${errorCheck['error']}")));
          }
        } catch (_) {

        }
        debugPrint("No valid JSON array found in response body.");
      }
    } catch (e) {
      debugPrint("Network/General Error fetching students: $e");
      setState(() => isLoading = false);
    }
  }


  String getInitials(String name) {
    if (name.isEmpty) return "?";
    List<String> parts = name.trim().split(" ");
    if (parts.length > 1) {
      return "${parts[0][0]}${parts[1][0]}".toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  Color getStudentColor(int index) {
    final colors = [
      Colors.blue.shade700,
      Colors.purple.shade600,
      Colors.orange.shade700,
      Colors.pink.shade600,
      Colors.teal.shade700,
      Colors.green.shade700,
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryGreen = const Color(0xFF19e619);
    final Color bgLight = const Color(0xFFf6f8f6);
    final Color textDark = const Color(0xFF0f172a);
    final Color textGrey = const Color(0xFF64748b);

    return Scaffold( floatingActionButton: FloatingActionButton.extended(
      onPressed: () async {

        final String classroomId = widget.classroom['id'].toString();

        final bool? result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EnrollStudentPage(classroomId: classroomId),
          ),
        );

        if (result == true) {
          fetchStudents();
        }
      },
      label: const Text("Enroll Student"),
      icon: const Icon(Icons.person_add),
      backgroundColor: primaryGreen,
      foregroundColor: Colors.white,
    ),
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.9),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Class Details",
          style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AttendanceDatePage(

                        classroom: widget.classroom,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.calendar_today, color: Colors.white),
                label: const Text(
                  "Take Attendance",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 5,
                ),
              ),
            ),
             SizedBox(height: 30,),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: primaryGreen.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.classroom['name'] ?? "Class Name",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textDark),
                  ),
                  const SizedBox(height: 20),
                  Divider(color: Colors.grey.shade100),
                  const SizedBox(height: 16),
                  Row(
                    children: [

                      Row(children: [
                        Icon(Icons.schedule, size: 20, color: primaryGreen),
                        const SizedBox(width: 6),
                        Text(widget.classroom['start_time'] ?? "--:--", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textDark)),
                      ]),
                      const SizedBox(width: 20),
                      Text("-", style: TextStyle(color: textGrey)),
                      const SizedBox(width: 20),

                      Row(children: [
                        Icon(Icons.timer_off_outlined, size: 20, color: textGrey),
                        const SizedBox(width: 6),
                        Text(widget.classroom['finish_time'] ?? "--:--", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textDark)),
                      ]),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),


            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Enrolled Students",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "${students.length} Students",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textGrey),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
            else if (students.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Column(
                    children: [
                      Icon(Icons.person_off_outlined, size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 10),
                      Text("No students in this class yet.", style: TextStyle(color: textGrey)),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: students.length,
                separatorBuilder: (c, i) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final student = students[index];

                  final name = student['name'] ?? "Unknown";
                  final id = student['id'].toString();

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Row(
                      children: [

                        Container(
                          height: 48,
                          width: 48,
                          decoration: BoxDecoration(
                            color: getStudentColor(index).withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            getInitials(name),
                            style: TextStyle(
                              color: getStudentColor(index),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: textDark,
                                ),
                              ),
                              Text(
                                "ID: $id",
                                style: TextStyle(color: textGrey, fontSize: 12),
                              ),
                            ],
                          ),
                        ),

                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _confirmDelete(int.parse(id));
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
void _confirmDelete(int studentId) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Remove Student"),
      content: const Text("Are you sure you want to remove this student?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            deleteStudent(studentId);
          },
          child: const Text("Delete", style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
}
}
