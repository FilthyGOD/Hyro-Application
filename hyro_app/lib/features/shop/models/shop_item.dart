/// Represents a shop item from the `objetos_tienda` table.
class ShopItem {
  final int id;
  final String nombre;
  final String categoria;
  final int precio;

  const ShopItem({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.precio,
  });

  factory ShopItem.fromJson(Map<String, dynamic> json) => ShopItem(
    id: json['id'] as int,
    nombre: json['nombre'] as String,
    categoria: json['categoria'] as String,
    precio: (json['precio'] as num).toInt(),
  );

  /// Emoji icon based on item ID ranges.
  String get icon {
    switch (id) {
      case 101:
        return '🎩';
      case 102:
        return '🤠';
      case 103:
        return '🤡';
      case 104:
        return '🧢';
      case 105:
        return '🎩';
      case 106:
        return '👑';
      case 107:
        return '🎓';
      case 201:
        return '🧐';
      case 202:
        return '🥸';
      case 203:
        return '🔴';
      case 204:
        return '🕶️';
      case 205:
        return '🎭';
      case 206:
        return '✨';
      case 301:
        return '🤵';
      case 302:
        return '🇲🇽';
      case 303:
        return '🎪';
      case 304:
        return '👕';
      case 401:
        return '🛡️';
      case 402:
        return '🧪';
      default:
        return '❓';
    }
  }

  /// Custom full-image asset path (PNG) for items that have been approved
  /// Returns null if the item still uses the fallback emoji.
  String? get imageAsset {
    switch (id) {
      // Nada items para Face (Cara) y Hats (Sombreros) usan la cara lisa.
      case 100:
      case 200:
        return 'assets/store/caraSinNada.png';
      case 101:
        return 'assets/store/sombreroElegante.png';
      case 102:
        return 'assets/store/sombreroMexicano.png';
      case 103:
        return 'assets/store/pelucaPayaso.png';
      case 201:
        return 'assets/store/monoculo.png';
      case 202:
        return 'assets/store/bigote.png';
      case 203:
        return 'assets/store/narizPayaso.png';
      // Nada item para Trajes (Cuerpo)
      case 300:
        return 'assets/store/cuerpoSinNada.png';
      case 301:
        return 'assets/store/trajeElegante.png';
      case 302:
        return 'assets/store/zarape.png';
      case 303:
        return 'assets/store/trajePayaso.png';
      default:
        return null;
    }
  }

  /// Custom SVG asset path for items that have SVG icons (e.g. cosmetics or consumables)
  String? get svgAsset {
    if ((id >= 104 && id <= 107) || (id >= 204 && id <= 206) || id == 304) {
      return 'assets/store/$id.svg';
    }
    if (id == 401 || nombre.toLowerCase().contains('protector')) {
      return 'assets/icons/Escudo.svg';
    }
    if (id == 402 ||
        (nombre.contains('3') &&
            (nombre.toLowerCase().contains('leccion') ||
                nombre.toLowerCase().contains('pomodoro') ||
                nombre.toLowerCase().contains('xp')))) {
      return 'assets/icons/BotellaDelgada.svg';
    }
    if (id == 403 ||
        (nombre.contains('6') &&
            (nombre.toLowerCase().contains('leccion') ||
                nombre.toLowerCase().contains('pomodoro') ||
                nombre.toLowerCase().contains('xp')))) {
      return 'assets/icons/Botella.svg';
    }
    return null;
  }

  /// Scale factor for card preview icon. Allows individual fine-tuning per item ID.
  double get previewScale {
    switch (id) {
      // Sombreros / Cascos
      case 104:
        return 0.9; // Soldado
      case 105:
        return 1.25; // Sombrero Gnomo
      case 106:
        return 1.30; // Construcción
      case 107:
        return 1.25; // Bruja

      // Cara
      case 204:
        return 1.6; //Oscuros
      case 205:
        return 1.6; // Flow
      case 206:
        return 1.3; //Gnomo

      // Cuerpo
      case 304:
        return 0.9; // Traje Gnomo

      default:
        return 1.0;
    }
  }

  /// Vertical offset (Y-axis translation) for card preview icon.
  /// Negative values shift the icon upward to prevent overlapping with text.
  double get previewOffsetY {
    switch (id) {
      case 204:
        return -14.0; // Oscuros
      case 205:
        return -14.0; // Flow
      default:
        return 0.0;
    }
  }
}
