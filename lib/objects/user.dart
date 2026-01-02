class User{
  int id;
  String name;
  String email;
  String phonenumber;
  String role;

  User(this.name, this.email, this.phonenumber, this.role,this.id);

  @override
  String toString() {
    return 'user{name: $name, email: $email, phonenumber: $phonenumber, role: $role}';
  }
}