import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../objects/user.dart';

class adminPage extends StatefulWidget {
  final User user;
  const adminPage({super.key, required this.user});

  @override
  State<adminPage> createState() => _adminPageState();
}

class _adminPageState extends State<adminPage> {

  Future<List<dynamic>> fetchUsers() async {
    final res = await http.get(Uri.parse("http://abohmed.atwebpages.com/get_all_users.php"));
    return jsonDecode(res.body);
  }

  Future<void> updateRole(String id, String newRole) async {
    await http.post(
      Uri.parse("http://abohmed.atwebpages.com/update_role.php"),
      body: {"id": id, "role": newRole},
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Roles"), backgroundColor: Colors.green),
      body: FutureBuilder<List<dynamic>>(
        future: fetchUsers(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              var u = snapshot.data![index];
              return ListTile(
                title: Text(u['name']),
                subtitle: Text("Current: ${u['role']}"),
                trailing: DropdownButton<String>(
                  value: u['role'],
                  items: ["student", "teacher", "admin"].map((role) {
                    return DropdownMenuItem(value: role, child: Text(role));
                  }).toList(),
                  onChanged: (val) => updateRole(u['id'].toString(), val!),
                ),
              );
            },
          );
        },
      ),
    );
  }
}