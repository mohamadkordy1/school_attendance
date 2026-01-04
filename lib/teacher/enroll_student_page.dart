import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class EnrollStudentPage extends StatefulWidget {
  final String classroomId;
  const EnrollStudentPage({super.key, required this.classroomId});

  @override
  State<EnrollStudentPage> createState() => _EnrollStudentPageState();
}

class _EnrollStudentPageState extends State<EnrollStudentPage> {
  List allStudents = [];
  List filteredStudents = [];
  Set<String> currentlyEnrolledIds = {};
  bool isLoading = true;
  bool isEnrolling = false;

  final TextEditingController searchController = TextEditingController();

  final Color primaryGreen = const Color(0xFF19e619);

  @override
  void initState() {
    super.initState();
    _fetchData();
    searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }



  Future<void> _fetchData() async {
    setState(() => isLoading = true);
    await Future.wait([
      _fetchAllStudents(),
      _fetchCurrentlyEnrolled(),
    ]);
    _applyFilter();
    setState(() => isLoading = false);
  }

  Future<void> _fetchAllStudents() async {
    try {
      final url = Uri.parse("http://abohmed.atwebpages.com/get_all_students.php");
      final res = await http.get(url);

      String rawBody = res.body.trim();
      int start = rawBody.indexOf('[');
      int end = rawBody.lastIndexOf(']');
      String cleanJson =
      (start != -1 && end != -1) ? rawBody.substring(start, end + 1) : '[]';

      final data = jsonDecode(cleanJson);
      if (data is List) {
        allStudents = data;
      }
    } catch (e) {
      debugPrint("Error fetching students: $e");
    }
  }

  Future<void> _fetchCurrentlyEnrolled() async {
    try {
      final url =
      Uri.parse("http://abohmed.atwebpages.com/get_classroom_students.php");
      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"classroom_id": widget.classroomId}),
      );

      String rawBody = res.body.trim();
      int start = rawBody.indexOf('[');
      int end = rawBody.lastIndexOf(']');
      String cleanJson =
      (start != -1 && end != -1) ? rawBody.substring(start, end + 1) : '[]';

      final data = jsonDecode(cleanJson);
      if (data is List) {
        currentlyEnrolledIds =
            data.map((s) => s['id'].toString()).toSet();
      }
    } catch (e) {
      debugPrint("Error fetching enrolled students: $e");
    }
  }



  void _onSearchChanged() {
    _applyFilter();
  }

  void _applyFilter() {
    final query = searchController.text.toLowerCase();

    final availableStudents = allStudents.where(
          (s) => !currentlyEnrolledIds.contains(s['id'].toString()),
    );

    setState(() {
      filteredStudents = availableStudents.where((student) {
        final name = (student['name'] ?? "").toString().toLowerCase();
        final id = student['id'].toString();
        return name.contains(query) || id.contains(query);
      }).toList();
    });
  }



  Future<void> _enrollStudent(String studentId, String studentName) async {
    if (isEnrolling) return;

    setState(() => isEnrolling = true);

    try {
      final url =
      Uri.parse("http://abohmed.atwebpages.com/enroll_student.php");

      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "classroom_id": widget.classroomId,
          "student_id": studentId,
        }),
      );

      String rawBody = res.body.trim();
      int start = rawBody.indexOf('{');
      int end = rawBody.lastIndexOf('}');
      String cleanJson =
      (start != -1 && end != -1) ? rawBody.substring(start, end + 1) : '{}';

      final data = jsonDecode(cleanJson);

      if (data["success"] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$studentName enrolled successfully")),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint("Enroll error: $e");
    } finally {
      setState(() => isEnrolling = false);
    }
  }



  String getInitials(String name) {
    if (name.isEmpty) return "?";
    final parts = name.split(" ");
    return parts.length > 1
        ? "${parts[0][0]}${parts[1][0]}".toUpperCase()
        : parts[0][0].toUpperCase();
  }

  Color getStudentColor(String id) {
    final colors = [
      Colors.blue.shade700,
      Colors.purple.shade600,
      Colors.orange.shade700,
      Colors.pink.shade600,
      Colors.teal.shade700,
      Colors.green.shade700,
    ];
    return colors[id.hashCode % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Enroll Student"),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [

          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Search by name or ID",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          Expanded(
            child: filteredStudents.isEmpty
                ? const Center(child: Text("No students found"))
                : ListView.separated(
              itemCount: filteredStudents.length,
              separatorBuilder: (_, __) =>
              const Divider(indent: 70),
              itemBuilder: (context, index) {
                final student = filteredStudents[index];
                final id = student['id'].toString();
                final name = student['name'] ?? "Unknown";
                final color = getStudentColor(id);

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color.withOpacity(0.15),
                    child: Text(
                      getInitials(name),
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(name),
                  subtitle: Text("ID: $id"),
                  trailing: isEnrolling
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2),
                  )
                      : Icon(Icons.add, color: primaryGreen),
                  onTap: () => _enrollStudent(id, name),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
