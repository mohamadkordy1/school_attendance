class Classroom {
  final int id;
  final String name;
  final String startTime;
  final String finishTime;
  final String teacherName;

  Classroom({
    required this.id,
    required this.name,
    required this.startTime,
    required this.finishTime,
    required this.teacherName
  });

  factory Classroom.fromJson(Map<String, dynamic> json) {
    return Classroom(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name'],
      startTime: json['start_time'],
      finishTime: json['finish_time'],
      teacherName: json['teacher_name'],
    );
  }
}