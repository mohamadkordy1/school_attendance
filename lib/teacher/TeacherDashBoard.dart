import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'create_classroom.dart';
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
      final url = Uri.parse(
        "http://abohmed.atwebpages.com/get_classrooms.php",
      );

      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "teacher_id": widget.user.id,
        }),
      );

      debugPrint("STATUS: ${res.statusCode}");
      debugPrint("BODY: ${res.body}");

      if (res.statusCode != 200) {
        throw Exception("Server error");
      }

      final decoded = jsonDecode(res.body);

      if (decoded is List) {
        setState(() {
          classrooms = decoded;
          isLoading = false;
        });
      } else {
        // ❗ Important: stop loader even if response is wrong
        setState(() => isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(decoded["error"] ?? "Invalid data format"),
          ),
        );
      }
    } catch (e) {
      // ❗ ALWAYS stop loader
      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title:  Text("welcome ${widget.user.name} "),
        backgroundColor: const Color(0xFF16A34A),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : classrooms.isEmpty
          ? const Center(child: Text("No classrooms found"))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: classrooms.length,
        itemBuilder: (context, index) {
          final c = classrooms[index];

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 6),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Classroom ${c["name"]}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    const Icon(Icons.schedule, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      "${c["start_time"]} - ${c["finish_time"]}",
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {
                      // TODO: open classroom details
                    },
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text("Enter Class"),
                  ),
                )
              ],
            ),
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF16A34A),
        onPressed: () {


          Navigator.of(context).push(MaterialPageRoute(builder: (context) =>  CreateClassroomPage(user: widget.user,),));

        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
