import 'package:flutter/material.dart';
import '../objects/user.dart';
class StudentHome extends StatelessWidget {
  const StudentHome({super.key, required this.user, });
final User user;
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body:
      Column(
        children: [// Back button with pop
          IconButton(
            icon:  Icon(
              Icons.arrow_back_ios, // You can also use Icons.chevron_left
              size: 28,
              color: Colors.black,  // Change color if needed
            ),
            onPressed: () {
              Navigator.of(context).pop(); // Go back to the previous page
            },
          ),

          Text("welcome Student ${user.name}"),
        ],
      )
      ,

    );
  }
}
