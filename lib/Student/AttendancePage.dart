import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../objects/user.dart';
import '../objects/classroom.dart';

class AttendancePage extends StatefulWidget {
  final Classroom classroom;
  final User user;

  const AttendancePage({
    super.key,
    required this.classroom,
    required this.user,
  });

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  /// date => status (Present / Absent)
  Map<String, String> attendanceMap = {};

  bool isLoading = true;
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  final Color primaryGreen = const Color(0xFF16A34A);
  final Color absentRed = const Color(0xFFDC2626);
  final Color emptyGray = const Color(0xFFD1D5DB);
  final Color backgroundColor = const Color(0xFFF8FCF8);

  @override
  void initState() {
    super.initState();
    fetchAttendance();
  }

  Future<void> fetchAttendance() async {
    setState(() => isLoading = true);

    final url = Uri.parse(
      "http://abohmed.atwebpages.com/get_attendance.php"
          "?student_id=${widget.user.id}"
          "&classroom_id=${widget.classroom.id}",
    );

    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        List data = jsonDecode(res.body);

        attendanceMap.clear();

        for (var item in data) {
          attendanceMap[item['date'].toString()] =
              item['status'].toString(); // Present / Absent
        }

        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Error: $e");
      setState(() => isLoading = false);
    }
  }

  String? getStatus(int day) {
    String formattedDate =
        "$selectedYear-${selectedMonth.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}";
    return attendanceMap[formattedDate]; // null = no record
  }

  double calculatePercentage(int totalDays) {
    if (totalDays == 0) return 0.0;

    int presentCount = attendanceMap.entries.where((e) {
      return e.value == 'Present' &&
          e.key.contains("-${selectedMonth.toString().padLeft(2, '0')}-");
    }).length;

    return (presentCount / totalDays) * 100;
  }

  int getDaysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  @override
  Widget build(BuildContext context) {
    int totalDays = getDaysInMonth(selectedYear, selectedMonth);
    double percent = calculatePercentage(totalDays);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          "Attendance History",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: primaryGreen))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                children: [
                  _buildStatsRow(percent),
                  const Divider(color: Colors.black12, height: 32),
                  _buildSelectors(),
                  const SizedBox(height: 20),
                  _buildCalendarGrid(totalDays),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.user.name.toUpperCase(),
          style: TextStyle(
            color: primaryGreen,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(
          "Class: ${widget.classroom.name}",
          style: const TextStyle(color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildStatsRow(double percent) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Monthly View",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(
          "${percent.toStringAsFixed(0)}% Present",
          style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildSelectors() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        DropdownButton<int>(
          value: selectedMonth,
          underline: const SizedBox(),
          items: List.generate(
            12,
                (i) => DropdownMenuItem(
              value: i + 1,
              child: Text("Month ${i + 1}"),
            ),
          ),
          onChanged: (val) => setState(() => selectedMonth = val!),
        ),
        DropdownButton<int>(
          value: selectedYear,
          underline: const SizedBox(),
          items: List.generate(
            5,
                (i) => DropdownMenuItem(
              value: 2026 - i,
              child: Text("${2026 - i}"),
            ),
          ),
          onChanged: (val) => setState(() => selectedYear = val!),
        ),
      ],
    );
  }

  Widget _buildCalendarGrid(int totalDays) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: totalDays,
      itemBuilder: (context, index) {
        final day = index + 1;
        String? status = getStatus(day);

        Color bgColor;
        Color textColor;

        if (status == 'Present') {
          bgColor = primaryGreen.withOpacity(0.15);
          textColor = primaryGreen;
        } else if (status == 'Absent') {
          bgColor = absentRed.withOpacity(0.15);
          textColor = absentRed;
        } else {
          bgColor = emptyGray.withOpacity(0.2);
          textColor = Colors.black38;
        }

        return Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            "$day",
            style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
          ),
        );
      },
    );
  }

  Widget _buildLegend() {
    return Row(
      children: [
        _dot(primaryGreen),
        const Text(" Present  "),
        _dot(absentRed),
        const Text(" Absent  "),
        _dot(emptyGray),
        const Text(" No Data"),
      ],
    );
  }

  Widget _dot(Color color) => Container(
    width: 12,
    height: 12,
    margin: const EdgeInsets.only(right: 6),
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
