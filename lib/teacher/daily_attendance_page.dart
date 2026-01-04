import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class DailyAttendancePage extends StatefulWidget {
  final DateTime selectedDate;

  final Map<String, dynamic> classroom;

  const DailyAttendancePage({
    super.key,
    required this.selectedDate,
    required this.classroom,
  });

  @override
  State<DailyAttendancePage> createState() => _DailyAttendancePageState();
}

class _DailyAttendancePageState extends State<DailyAttendancePage> {

  static const Color primaryGreen = Color(0xFF19e619);
  static const Color backgroundLight = Color(0xFFf6f8f6);
  static const Color cardLight = Colors.white;
  static const Color presentColor = Color(0xFF22C55E);
  static const Color absentColor = Color(0xFFEF4444);

  List students = [];
  bool isLoading = true;
  bool isSaving = false;
  bool alreadySaved = false;


  Map<String, String> attendance = {};


  @override
  void initState() {
    super.initState();

    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);

    final String classroomId = widget.classroom['id'].toString();
    final String sqlDate = DateFormat('yyyy-MM-dd').format(widget.selectedDate);

    try {
      final url = Uri.parse("http://abohmed.atwebpages.com/get_attendance.php");

      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "classroom_id": classroomId,
          "date": sqlDate,
        }),
      );

      String rawBody = res.body.trim();
      int start = rawBody.indexOf('[');
      int end = rawBody.lastIndexOf(']');
      String cleanJson = (start != -1 && end != -1) ? rawBody.substring(start, end + 1) : '[]';

      final List data = jsonDecode(cleanJson);

      if (data.isNotEmpty) {
        students = data;
        for (var record in data) {
          attendance[record['id'].toString()] = record['status'];
        }
        alreadySaved = true;
      } else {
        await _fetchClassroomStudents();
        alreadySaved = false;

        for (var student in students) {
          attendance[student['id'].toString()] = 'Present';
        }
      }

    } catch (e) {
      debugPrint("Error loading attendance data: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to load attendance records.")),
        );
      }
    }

    setState(() => isLoading = false);
  }


  Future<void> _fetchClassroomStudents() async {
    try {
      final url = Uri.parse("http://abohmed.atwebpages.com/get_classroom_students.php");

      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"classroom_id": widget.classroom['id']}),
      );


      String rawBody = res.body.trim();
      int start = rawBody.indexOf('[');
      int end = rawBody.lastIndexOf(']');
      String cleanJson = (start != -1 && end != -1) ? rawBody.substring(start, end + 1) : '[]';

      final data = jsonDecode(cleanJson);
      if (data is List) {
        students = data;
      }

    } catch (e) {
      debugPrint("Error fetching students for fresh marking: $e");
    }
  }


  Future<void> _saveAttendance() async {

    if (isSaving || students.isEmpty) return;

    setState(() => isSaving = true);


    List<Map<String, String>> dataToSend = students.map((s) {
      final studentId = s['id'].toString();
      return {
        "classroom_id": widget.classroom['id'].toString(),
        "student_id": studentId,
        "date": DateFormat('yyyy-MM-dd').format(widget.selectedDate),
        "status": attendance[studentId] ?? 'Present',
      };
    }).toList();
    debugPrint("Saving Attendance for Classroom ID: ${widget.classroom['id']}");
    debugPrint("Date: ${DateFormat('yyyy-MM-dd').format(widget.selectedDate)}");
    debugPrint("JSON Body Sent: ${jsonEncode({"attendance_data": dataToSend})}");
    try {
      final url = Uri.parse("http://abohmed.atwebpages.com/save_attendance.php");

      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"attendance_data": dataToSend}),
      );


      String rawBody = res.body.trim();
      int start = rawBody.indexOf('{');
      int end = rawBody.lastIndexOf('}');
      String cleanJson = (start != -1 && end != -1) ? rawBody.substring(start, end + 1) : '{}';

      final data = jsonDecode(cleanJson);

      if (data["success"] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data["message"] ?? "Attendance saved!")),
          );

          setState(() {
            alreadySaved = true;
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data["error"] ?? "Failed to save attendance.")),
          );
        }
      }
    } catch (e) {
      debugPrint("Save Attendance Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Network error. Could not save attendance.")),
        );
      }
    } finally {
      setState(() => isSaving = false);
    }
  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        title: Text(
          "Attendance: ${widget.classroom['name']}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [

          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              DateFormat('EEEE, MMMM d, y').format(widget.selectedDate),
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),


          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : students.isEmpty
                ? Center(child: Text("No students enrolled in this class.", style: TextStyle(color: Colors.grey.shade600)))
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: students.length,
              itemBuilder: (context, index) {
                final student = students[index];
                final studentId = student['id'].toString();
                final isPresent = attendance[studentId] == 'Present';

                return _AttendanceCard(
                  name: student['name'] ?? 'N/A',
                  studentId: studentId,
                  isPresent: isPresent,
                  isLocked: alreadySaved,
                  onMark: (status) {
                    if (!alreadySaved) {
                      setState(() {
                        attendance[studentId] = status;
                      });
                    }
                  },
                );
              },
            ),
          ),


          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: alreadySaved || students.isEmpty || isSaving ? null : _saveAttendance,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  disabledBackgroundColor: primaryGreen.withOpacity(0.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  foregroundColor: Colors.white,
                ),
                child: isSaving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(

                  alreadySaved ? "Attendance Saved (View Only)" : "Save Attendance",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _AttendanceCard extends StatelessWidget {
  final String name;
  final String studentId;
  final bool isPresent;
  final bool isLocked;
  final Function(String status) onMark;

  const _AttendanceCard({
    required this.name,
    required this.studentId,
    required this.isPresent,
    required this.isLocked,
    required this.onMark,
  });

  static const Color cardLight = Colors.white;
  static const Color presentColor = Color(0xFF22C55E);
  static const Color absentColor = Color(0xFFEF4444);
  static const Color primaryBlue = Color(0xFF3B82F6);

  String getInitials(String name) {
    if (name.isEmpty) return "?";
    List<String> parts = name.trim().split(" ");
    if (parts.length > 1) {
      return "${parts[0][0]}${parts[1][0]}".toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  Color getStudentColor(String id) {
    final colors = [
      Colors.blue.shade700, Colors.purple.shade600, Colors.orange.shade700,
      Colors.pink.shade600, Colors.teal.shade700, Colors.green.shade700,
    ];
    int hash = 0;
    for (int i = 0; i < id.length; i++) {
      hash += id.codeUnitAt(i);
    }
    return colors[hash % colors.length];
  }


  @override
  Widget build(BuildContext context) {
    final initials = getInitials(name);
    final avatarColor = getStudentColor(studentId);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: cardLight,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)
          ]
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: avatarColor.withOpacity(0.15),
                child: Text(
                  initials,
                  style: TextStyle(
                    color: avatarColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    color: Color(0xFF0f172a),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),

              if (isLocked)
                Icon(
                  isPresent ? Icons.check_circle : Icons.cancel,
                  color: isPresent ? presentColor : absentColor,
                ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatusButton(
                label: "Absent",
                color: absentColor,
                selected: !isPresent,
                isLocked: isLocked,
                onTap: () => onMark('Absent'),
              ),
              _StatusButton(
                label: "Present",
                color: presentColor,
                selected: isPresent,
                isLocked: isLocked,
                onTap: () => onMark('Present'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final bool isLocked;
  final VoidCallback onTap;

  const _StatusButton({
    required this.label,
    required this.color,
    required this.selected,
    required this.isLocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color buttonColor = selected ? color : Colors.grey.shade300;

    if (isLocked) {
      buttonColor = selected ? color.withOpacity(0.5) : Colors.grey.shade300.withOpacity(0.5);
    }

    Color textColor = selected ? Colors.white : Colors.grey.shade700;
    if (isLocked && !selected) textColor = Colors.grey.shade400;


    return GestureDetector(
      onTap: isLocked ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
        decoration: BoxDecoration(
          color: buttonColor,
          borderRadius: BorderRadius.circular(999),
          border: selected ? Border.all(color: color, width: 2) : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
