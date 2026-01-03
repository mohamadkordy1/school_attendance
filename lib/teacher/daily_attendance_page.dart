import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class DailyAttendancePage extends StatefulWidget {
  final DateTime selectedDate;
  // Assuming the classroom object passed has an 'id' and 'name'
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
  // Theme Colors
  static const Color primaryGreen = Color(0xFF19e619);
  static const Color backgroundLight = Color(0xFFf6f8f6);
  static const Color cardLight = Colors.white;
  static const Color presentColor = Color(0xFF22C55E); // Green
  static const Color absentColor = Color(0xFFEF4444); // Red

  List students = []; // List of students to display
  bool isLoading = true;
  bool isSaving = false;
  bool alreadySaved = false;

  /// studentId (String) -> 'Present' or 'Absent'
  Map<String, String> attendance = {};


  @override
  void initState() {
    super.initState();
    // One function call to determine both the list and the status
    _loadData();
  }

  // Unified function to either load saved attendance OR load the student list for marking
  Future<void> _loadData() async {
    setState(() => isLoading = true);

    final String classroomId = widget.classroom['id'].toString();
    final String sqlDate = DateFormat('yyyy-MM-dd').format(widget.selectedDate);

    // 1. Try to fetch existing attendance for this date
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

      // Clean JSON
      String rawBody = res.body.trim();
      int start = rawBody.indexOf('[');
      int end = rawBody.lastIndexOf(']');
      String cleanJson = (start != -1 && end != -1) ? rawBody.substring(start, end + 1) : '[]';

      final List data = jsonDecode(cleanJson);

      if (data.isNotEmpty) {
        // 2. SUCCESS: Attendance already exists for this date!
        students = data;
        for (var record in data) {
          attendance[record['id'].toString()] = record['status'];
        }
        alreadySaved = true; // Lock the UI
      } else {
        // 3. FAIL: Attendance does NOT exist. Load the student list for a fresh marking.
        await _fetchClassroomStudents();
        alreadySaved = false; // Allow saving
        // Initialize all to Present for fresh marking
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


  // Fetches students enrolled in this classroom (Called only if attendance does not exist)
  Future<void> _fetchClassroomStudents() async {
    try {
      final url = Uri.parse("http://abohmed.atwebpages.com/get_classroom_students.php");

      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"classroom_id": widget.classroom['id']}),
      );

      // Clean JSON
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


  // Saves the attendance data to the database
  Future<void> _saveAttendance() async {
    // We remove the check `if (alreadySaved)` here because the PHP server
    // will now handle the duplicate check and return a nice error message if needed.
    if (isSaving || students.isEmpty) return;

    setState(() => isSaving = true);

    // Prepare data array for PHP script
    List<Map<String, String>> dataToSend = students.map((s) {
      final studentId = s['id'].toString();
      return {
        "classroom_id": widget.classroom['id'].toString(),
        "student_id": studentId,
        "date": DateFormat('yyyy-MM-dd').format(widget.selectedDate), // YYYY-MM-DD format for SQL
        "status": attendance[studentId] ?? 'Present', // Default to Present
      };
    }).toList();
    debugPrint("Saving Attendance for Classroom ID: ${widget.classroom['id']}");
    debugPrint("Date: ${DateFormat('yyyy-MM-dd').format(widget.selectedDate)}");
    debugPrint("JSON Body Sent: ${jsonEncode({"attendance_data": dataToSend})}"); // Print the actual JSON string
    try {
      final url = Uri.parse("http://abohmed.atwebpages.com/save_attendance.php");

      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"attendance_data": dataToSend}),
      );

      // Clean JSON
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
          // Only set alreadySaved = true on successful insertion
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
    // ... (rest of the build method is unchanged)
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
          // DATE DISPLAY
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

          // CHILDREN LIST
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
                  isLocked: alreadySaved, // Set locking based on the fetch result
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

          // SAVE BUTTON
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
                  // Display status based on fetch result
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

// Re-using the existing AttendanceCard and StatusButton widgets (unchanged)
class _AttendanceCard extends StatelessWidget {
  final String name;
  final String studentId;
  final bool isPresent;
  final bool isLocked;
  final Function(String status) onMark; // status is 'Present' or 'Absent'

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
                    color: Color(0xFF0f172a), // textDark
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              // Status indicator when locked
              if (isLocked)
                Icon(
                  isPresent ? Icons.check_circle : Icons.cancel,
                  color: isPresent ? presentColor : absentColor,
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Buttons Row
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

    // Dim the button if locked, regardless of selection
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

// Note: You must ensure these utility classes are present in your file.