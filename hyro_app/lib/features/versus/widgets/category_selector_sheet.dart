import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../data/models/category_model.dart';

/// BottomSheet para seleccionar la materia en un duelo de materias cruzadas.
class CategorySelectorSheet extends StatelessWidget {
  final List<CategoryModel> categorias;

  const CategorySelectorSheet({
    super.key,
    required this.categorias,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.cardBorder, width: 1.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selecciona tu Materia',
            style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Para este duelo de materias cruzadas, usarás las preguntas de la materia que elijas.',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: categorias.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final cat = categorias[index];
                final color = Color(cat.colorValue);

                return ListTile(
                  tileColor: AppColors.surfaceLight,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.cardBorder),
                  ),
                  leading: Icon(
                    cat.iconCodePoint != null
                        ? IconData(cat.iconCodePoint!, fontFamily: 'MaterialIcons')
                        : Icons.folder_rounded,
                    color: color,
                  ),
                  title: Text(
                    cat.name,
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                  ),
                  onTap: () => Navigator.pop(context, cat),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
