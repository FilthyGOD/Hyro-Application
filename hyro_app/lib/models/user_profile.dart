import 'package:isar/isar.dart';

part 'user_profile.g.dart';

enum UserType { personal, school }

@collection
class UserProfile {
  Id id = Isar.autoIncrement; // you can also use id = null to auto increment

  String? name;

  @Index(unique: true, replace: true)
  late String usernameOrEmail;

  @enumerated
  UserType type = UserType.personal;

  // School specific fields
  String? schoolCode;

  // Track if they are currently logged in
  bool isActivelyLoggedIn = true;
}
