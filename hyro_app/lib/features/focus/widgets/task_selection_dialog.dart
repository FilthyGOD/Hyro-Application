import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../categories/category_provider.dart';
import '../../tasks/tasks_provider.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/task_model.dart';

class TaskSelectionDialog extends StatefulWidget {
  const TaskSelectionDialog({super.key});

  @override
  State<TaskSelectionDialog> createState() => _TaskSelectionDialogState();
}

class _TaskSelectionDialogState extends State<TaskSelectionDialog> {
  String? _selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.read<TaskProvider>();
    final isAuth = taskProvider.isAuthenticated();
    final userId = taskProvider.getUserId();

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _selectedCategoryId == null
            ? _buildCategorySelection(context, isAuth, userId)
            : _buildTaskSelection(context, isAuth, userId, _selectedCategoryId!),
      ),
    );
  }

  Widget _buildCategorySelection(BuildContext context, bool isAuth, String? userId) {
    return Padding(
      key: const ValueKey('Categories'),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 24),
              Text(
                'Selecciona Categoría',
                style: AppTypography.h3,
                textAlign: TextAlign.center,
              ),
              IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 16),
          Flexible(
            child: isAuth && userId != null
                ? _buildRemoteCategories(userId)
                : _buildLocalCategories(context),
          ),
          const Divider(color: AppColors.cardBorder),
          ListTile(
            leading: const Icon(Icons.play_arrow, color: Colors.white54),
            title: const Text(
              'Empezar sin tarea',
              style: TextStyle(color: Colors.white54),
            ),
            onTap: () => Navigator.pop(context, 'NO_TASK'),
          ),
        ],
      ),
    );
  }

  Widget _buildRemoteCategories(String userId) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client
          .from('categorias')
          .stream(primaryKey: ['id']).eq('usuario_id', userId),
      builder: (context, snapshot) {
         if (!snapshot.hasData && snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ));
         }
         final List<CategoryModel> categories = (snapshot.data ?? []).map((m) => CategoryModel.fromSupabaseJson(m)).toList();
         return _buildCategoryList(categories);
      },
    );
  }

  Widget _buildLocalCategories(BuildContext context) {
    final categories = context.watch<CategoryProvider>().categories;
    return _buildCategoryList(categories);
  }

  Widget _buildCategoryList(List<CategoryModel> categories) {
    if (categories.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          "No hay categorias disponibles.",
          style: AppTypography.bodyMedium,
          textAlign: TextAlign.center,
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      itemCount: categories.length + 1, // +1 for "Sin Categoria"
      itemBuilder: (context, index) {
        if (index == categories.length) {
          // Additional fixed option
           return ListTile(
            leading: const Icon(Icons.folder_outlined, color: Colors.white54),
            title: Text('Sin Categoría', style: AppTypography.bodyMedium),
            onTap: () {
              setState(() {
                _selectedCategoryId = 'SIN_CATEGORIA';
              });
            },
          );
        }
        
        final category = categories[index];
        final color = Color(category.colorValue);
        
        return ListTile(
          leading: Icon(
            category.iconCodePoint != null ? IconData(category.iconCodePoint!, fontFamily: 'MaterialIcons') : Icons.folder,
            color: color,
          ),
          title: Text(category.name, style: AppTypography.bodyMedium),
          onTap: () {
            setState(() {
              _selectedCategoryId = category.id;
            });
          },
        );
      },
    );
  }

  // ============== TASK SELECTION VIEW ==============

  Widget _buildTaskSelection(BuildContext context, bool isAuth, String? userId, String catId) {
    return Padding(
      key: const ValueKey('Tasks'),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white54),
                onPressed: () {
                  setState(() {
                    _selectedCategoryId = null;
                  });
                },
              ),
              Expanded(
                child: Text(
                  'Tareas',
                  style: AppTypography.h3,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 48), // Balancing title
            ],
          ),
          const SizedBox(height: 16),
          Flexible(
            child: isAuth && userId != null
                ? _buildRemoteTasks(userId, catId)
                : _buildLocalTasks(context, catId),
          ),
        ],
      ),
    );
  }

  Widget _buildRemoteTasks(String userId, String catId) {
    final query = Supabase.instance.client
          .from('tareas')
          .stream(primaryKey: ['id'])
          .eq('usuario_id', userId);
          
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: query,
      builder: (context, snapshot) {
         if (!snapshot.hasData && snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ));
         }
         var tasks = (snapshot.data ?? []).map((m) => TaskModel.fromSupabaseJson(m)).toList();
         
         // Filter natively after fetch since is(null) on stream filters might be tricky in pure dart stream API.
         tasks = tasks.where((t) {
            if (catId == 'SIN_CATEGORIA') return t.categoryId == null;
            return t.categoryId == catId;
         }).toList();
         
         return _buildTaskList(tasks);
      },
    );
  }

  Widget _buildLocalTasks(BuildContext context, String catId) {
    final allTasks = context.watch<TaskProvider>().tasks;
    final filtered = allTasks.where((t) {
      if (catId == 'SIN_CATEGORIA') return t.categoryId == null && (t.category == null || t.category!.isEmpty);
      return t.categoryId == catId;
    }).toList();
    
    return _buildTaskList(filtered);
  }

  Widget _buildTaskList(List<TaskModel> tasks) {
    final pending = tasks.where((t) => !t.isCompleted).toList();
    if (pending.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          "Sin tareas pendientes en esta categoría.",
          style: AppTypography.bodyMedium,
          textAlign: TextAlign.center,
        ),
      );
    }
    
    return ListView.builder(
      shrinkWrap: true,
      itemCount: pending.length,
      itemBuilder: (context, index) {
        final task = pending[index];
        return ListTile(
          leading: Icon(
            Icons.check_circle_outline,
            color: Color(task.priorityColorValue),
          ),
          title: Text(task.title, style: AppTypography.bodyMedium),
          subtitle: Text(
            '${task.pomodorosCompleted} / ${task.pomodorosTarget} Pomodoros',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          onTap: () => Navigator.pop(context, {'id': task.id, 'title': task.title}), // Passing the TASK ID back with title
        );
      },
    );
  }
}
