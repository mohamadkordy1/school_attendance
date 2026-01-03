class Classroom{
  int id;
  int teacher_id;

  String start_time;
  String name;
  String finish_time;

  Classroom(this.id, this.teacher_id, this.start_time, this.name,
      this.finish_time);

  @override
  String toString() {
    return 'classroom{id: $id, teacher_id: $teacher_id, start_time: $start_time, name: $name, finish_time: $finish_time}';
  }


}