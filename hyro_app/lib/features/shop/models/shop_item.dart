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
      case 101: return '🎩';
      case 102: return '🤠';
      case 103: return '🤡';
      case 201: return '🧐';
      case 202: return '🥸';
      case 203: return '🔴';
      case 301: return '🤵';
      case 302: return '🇲🇽';
      case 303: return '🎪';
      default:  return '❓';
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
}
