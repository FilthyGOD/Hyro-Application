/// Stubs para web — no hay Isar ni Hive en el navegador.

Future<Map<String, int>?> loadLocalProfile(dynamic isar) async => null;

Future<void> updateLocalProfile(dynamic isar, Map<String, dynamic> response, int countVal) async {}

void updateLocalCoins(dynamic isar, int dbMonedas) {}

Future<int?> checkStreakJudge(dynamic isar, int rachaActual, String? userId) async => null;

Future<Map<String, int>?> grantXPLocally(dynamic isar, int xp) async => null;

Future<Map<String, int>?> syncDynamicStatsLocally(dynamic isar, int dynamicStreak, int newlyAddedMinutes) async => null;

Future<int?> modifyCoinsLocally(dynamic isar, int cantidad) async => null;
