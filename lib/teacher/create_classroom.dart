import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../objects/user.dart';

class CreateClassroomPage extends StatefulWidget {
  final User user;
  const CreateClassroomPage({super.key, required this.user});

  @override
  State<CreateClassroomPage> createState() => _CreateClassroomPageState();
}

class _CreateClassroomPageState extends State<CreateClassroomPage> {
  final nameCtrl = TextEditingController();
  final startCtrl = TextEditingController();
  final finishCtrl = TextEditingController();

  bool isLoading = false;

  Future<void> saveClassroom() async {
    if (nameCtrl.text.isEmpty ||
        startCtrl.text.isEmpty ||
        finishCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All fields are required")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final res = await http.post(
        Uri.parse("http://abohmed.atwebpages.com/create_classroom.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "teacher_id": widget.user.id,
          "name": nameCtrl.text.trim(),
          "start_time": startCtrl.text.trim(),
          "finish_time": finishCtrl.text.trim(),
        }),
      );

      // ✅ ALWAYS LOG SERVER RESPONSE
      debugPrint("STATUS CODE: ${res.statusCode}");
      debugPrint("RAW RESPONSE: ${res.body}");

      setState(() => isLoading = false);

      try {
        final data = jsonDecode(res.body);

        debugPrint("DECODED JSON: $data");

        if (res.statusCode == 200 && data["success"] == true) {
          Navigator.pop(context, true);
        } else {
          debugPrint("BACKEND ERROR: ${data["error"]}");

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data["error"] ?? "Unknown error")),
          );
        }
      } catch (e) {
        // ❌ JSON parsing error (HTML response, PHP error, etc.)
        debugPrint("JSON PARSE ERROR: $e");

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Invalid server response")),
        );
      }
    } catch (e) {
      // ❌ Network / request error
      debugPrint("REQUEST ERROR: $e");

      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Network error")),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("New Classroom"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: "Class Name"),
            ),
            TextField(
              controller: startCtrl,
              decoration: const InputDecoration(labelText: "Start Time (09:00)"),
            ),
            TextField(
              controller: finishCtrl,
              decoration: const InputDecoration(labelText: "Finish Time (10:30)"),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : saveClassroom,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Create Classroom"),
              ),
            )
          ],
        ),
      ),
    );
  }
}
