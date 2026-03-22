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
}
