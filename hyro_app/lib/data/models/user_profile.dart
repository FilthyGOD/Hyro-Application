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

  // Guest Mode local gamification data
  int nivel = 1;
  int experiencia = 0;
  int monedas = 0;
  List<int> comprasLocales = [];
  int? itemEquipadoLocal;

  // Offline-first user profile statistics
  int rachaActual = 0;
  int rachaMaxima = 0;
  int minutosEnfoqueTotal = 0;
  int tareasCompletadasTotal = 0;
  int sesionesMes = 0;
}
