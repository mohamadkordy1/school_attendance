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

  Future<void> _pickTime(TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked != null) {

      final String formatted =
          "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
      setState(() {
        controller.text = formatted;
      });
    }
  }

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
        Uri.parse("//abohmed.atwebpages.com/store_classroom.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "teacher_id": widget.user.id,
          "name": nameCtrl.text.trim(),
          "start_time": startCtrl.text.trim(),
          "finish_time": finishCtrl.text.trim(),
        }),
      );

      debugPrint("STATUS CODE: ${res.statusCode}");
      debugPrint("RAW RESPONSE: ${res.body}");

      setState(() => isLoading = false);

      try {

        String cleanJson = res.body;
        int firstBrace = res.body.indexOf('{');
        int lastBrace = res.body.lastIndexOf('}');
        if (firstBrace != -1 && lastBrace != -1) {
          cleanJson = res.body.substring(firstBrace, lastBrace + 1);
        }

        final data = jsonDecode(cleanJson);
        debugPrint("DECODED JSON: $data");

        if (res.statusCode == 200 && data["success"] == true) {
          if (mounted) {
            Navigator.pop(context, true);
          }
        } else {
          debugPrint("BACKEND ERROR: ${data["error"]}");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(data["error"] ?? "Unknown error")),
            );
          }
        }
      } catch (e) {
        debugPrint("JSON PARSE ERROR: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Invalid server response")),
          );
        }
      }
    } catch (e) {
      debugPrint("REQUEST ERROR: $e");
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Network error")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    final outlineBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text("New Classroom", style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Class Details",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: "Class Name",
                hintText: "e.g. Mathematics 101",
                prefixIcon: const Icon(Icons.class_outlined),
                border: outlineBorder,
                enabledBorder: outlineBorder,
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            const SizedBox(height: 20),


            TextField(
              controller: startCtrl,
              readOnly: true,
              onTap: () => _pickTime(startCtrl),
              decoration: InputDecoration(
                labelText: "Start Time",
                hintText: "09:00",
                prefixIcon: const Icon(Icons.access_time),
                suffixIcon: const Icon(Icons.arrow_drop_down),
                border: outlineBorder,
                enabledBorder: outlineBorder,
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            const SizedBox(height: 20),


            TextField(
              controller: finishCtrl,
              readOnly: true,
              onTap: () => _pickTime(finishCtrl),
              decoration: InputDecoration(
                labelText: "Finish Time",
                hintText: "10:30",
                prefixIcon: const Icon(Icons.access_time_filled),
                suffixIcon: const Icon(Icons.arrow_drop_down),
                border: outlineBorder,
                enabledBorder: outlineBorder,
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),

            const SizedBox(height: 40),


            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: isLoading ? null : saveClassroom,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                )
                    : const Text(
                  "Create Classroom",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}