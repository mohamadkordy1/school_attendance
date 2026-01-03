import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Only required if fetching class data here
import 'daily_attendance_page.dart'; // We will create this next

// Using a simple Map as a placeholder for your Classroom model
// Replace this with your actual Classroom model if necessary
class Classroom {
  final int id;
  final String name;
  Classroom({required this.id, required this.name});
}

class AttendanceDatePage extends StatefulWidget {
  // Assuming the classroom object passed from the dashboard has an 'id'
  final Map<String, dynamic> classroom;

  const AttendanceDatePage({super.key, required this.classroom});

  @override
  State<AttendanceDatePage> createState() => _AttendanceDatePageState();
}

class _AttendanceDatePageState extends State<AttendanceDatePage> {
  // Theme Colors
  static const Color primaryGreen = Color(0xFF19e619);
  static const Color backgroundLight = Color(0xFFf6f8f6);
  static const Color textDark = Color(0xFF0f172a);
  static const Color cardLight = Colors.white;

  DateTime displayedMonth = DateTime.now();
  DateTime? selectedDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        backgroundColor: primaryGreen,
        title: Text(
          "Select Attendance Date",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // SCROLLABLE CALENDAR
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: cardLight,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
                      ]
                  ),
                  child: Column(
                    children: [
                      // MONTH + YEAR NAV
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _navButton(Icons.chevron_left, () {
                            setState(() {
                              displayedMonth = DateTime(displayedMonth.year, displayedMonth.month - 1);
                            });
                          }),
                          Text(
                            "${_monthName(displayedMonth.month)} ${displayedMonth.year}",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            ),
                          ),
                          _navButton(Icons.chevron_right, () {
                            setState(() {
                              displayedMonth = DateTime(displayedMonth.year, displayedMonth.month + 1);
                            });
                          }),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // WEEKDAYS
                      GridView.count(
                        crossAxisCount: 7,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: const [
                          _WeekDay("Su"), _WeekDay("Mo"), _WeekDay("Tu"), _WeekDay("We"),
                          _WeekDay("Th"), _WeekDay("Fr"), _WeekDay("Sa"),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // DAYS GRID
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: 42,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                        ),
                        itemBuilder: (context, index) {
                          final firstDay = DateTime(displayedMonth.year, displayedMonth.month, 1);
                          // Adjusting for Dart's Monday=1, Sunday=7 to Sunday=0
                          final startWeekday = firstDay.weekday % 7;
                          final day = index - startWeekday + 1;
                          final daysInMonth = DateUtils.getDaysInMonth(displayedMonth.year, displayedMonth.month);

                          if (day < 1 || day > daysInMonth) {
                            return const SizedBox();
                          }

                          final date = DateTime(displayedMonth.year, displayedMonth.month, day);

                          final isSelected = selectedDate != null &&
                              selectedDate!.year == date.year &&
                              selectedDate!.month == date.month &&
                              selectedDate!.day == date.day;

                          // Prevent selecting future dates
                          final isFuture = date.isAfter(DateTime.now().subtract(const Duration(hours: 24)));

                          return _DayCell(
                            text: "$day",
                            selected: isSelected,
                            isDisabled: isFuture,
                            onTap: isFuture ? () {} : () {
                              setState(() {
                                selectedDate = date;
                              });
                            },
                          );
                        },
                      ),

                      const SizedBox(height: 12),

                      // SELECTED DATE DISPLAY
                      if (selectedDate != null)
                        Text(
                          _formatFullDate(selectedDate!),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // CONTINUE BUTTON
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedDate == null
                      ? null
                      : () {
                    // Navigate to the daily attendance page
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) => DailyAttendancePage(
                        classroom: widget.classroom,
                        selectedDate: selectedDate!,
                      ),
                    ));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    disabledBackgroundColor: primaryGreen.withOpacity(0.5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    "Take Attendance",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navButton(IconData icon, VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: textDark),
      style: IconButton.styleFrom(
        backgroundColor: Colors.grey.shade100,
        shape: const CircleBorder(),
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      "January", "February", "March", "April",
      "May", "June", "July", "August",
      "September", "October", "November", "December"
    ];
    return months[month - 1];
  }

  String _formatFullDate(DateTime date) {
    return "${date.day} ${_monthName(date.month)} ${date.year}";
  }
}

class _WeekDay extends StatelessWidget {
  final String label;
  const _WeekDay(this.label);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label,
        style: TextStyle(
          color: Colors.grey.shade500,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final String text;
  final bool selected;
  final bool isDisabled;
  final VoidCallback onTap;

  const _DayCell({
    required this.text,
    required this.onTap,
    this.selected = false,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF19e619) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isDisabled ? Colors.grey.shade400 : (selected ? Colors.white : Colors.grey.shade800),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}