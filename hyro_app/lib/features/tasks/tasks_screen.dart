import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/glass_card.dart';

/// Tasks screen — full task management view.
class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  int _selectedFilter = 0; // 0=All, 1=Pending, 2=Completed

  // ── Demo data ──
  final List<_DemoTask> _tasks = [
    _DemoTask(
      title: 'Complete Research Paper',
      subtitle: 'Due Today, 5:00 PM',
      priority: 'HIGH PRIORITY',
      priorityColor: const Color(0xFFEF4444),
      pomodoros: 4,
    ),
    _DemoTask(
      title: 'Design System Update',
      subtitle: 'Tomorrow, 10:00 AM',
      priority: 'MEDIUM',
      priorityColor: const Color(0xFFF59E0B),
      pomodoros: 2,
    ),
    _DemoTask(
      title: 'Weekly Grocery Shopping',
      subtitle: 'Sat, 2:00 PM',
      priority: 'LOW',
      priorityColor: const Color(0xFF22C55E),
      pomodoros: 1,
    ),
    _DemoTask(
      title: 'Calculus Review',
      subtitle: 'Mon, 9:00 AM',
      priority: 'HIGH PRIORITY',
      priorityColor: const Color(0xFFEF4444),
      pomodoros: 3,
    ),
  ];

  final List<_CategoryData> _categories = [
    _CategoryData(
      name: 'University',
      icon: Icons.school_rounded,
      pending: 3,
      color: AppColors.primary,
    ),
    _CategoryData(
      name: 'Personal',
      icon: Icons.person_rounded,
      pending: 5,
      color: const Color(0xFFEC4899),
    ),
    _CategoryData(
      name: 'Work',
      icon: Icons.work_rounded,
      pending: 2,
      color: const Color(0xFF22C55E),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth > 800;

        return Padding(
          padding: EdgeInsets.only(
            left: isLargeScreen ? 72 : 16,
            top: 32,
            right: 32,
            bottom: 32,
          ),
          child:
              isLargeScreen
                  ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 65, child: _buildLeftContent()),
                      const SizedBox(width: 32),
                      SizedBox(width: 320, child: _buildRightContent()),
                    ],
                  )
                  : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLeftContent(),
                        const SizedBox(height: 32),
                        _buildRightContent(),
                      ],
                    ),
                  ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════
  // LEFT CONTENT
  // ═══════════════════════════════════════════════

  Widget _buildLeftContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──
        _buildHeader(),
        const SizedBox(height: 24),
        // ── Category Cards ──
        _buildCategoryCards(),
        const SizedBox(height: 32),
        // ── Today's Focus + Filters ──
        _buildTodaysFocusHeader(),
        const SizedBox(height: 16),
        // ── Task List ──
        ..._buildTaskList(),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mis Pendientes', style: AppTypography.h1),
                  const SizedBox(height: 4),
                  Text(
                    'Monday, Mar 9 • Focus Streak: 5 days 🔥',
                    style: AppTypography.bodyMedium,
                  ),
                ],
              ),
            ),
            // Search bar
            Container(
              width: 200,
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: AppColors.textTertiary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search tasks...',
                        hintStyle: AppTypography.bodySmall,
                        border: InputBorder.none,
                        isCollapsed: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // New Task button
            ElevatedButton.icon(
              onPressed: _showAddTaskDialog,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New Task'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryCards() {
    return Row(
      children:
          _categories
              .map(
                (cat) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: cat != _categories.last ? 16 : 0,
                    ),
                    child: _CategoryCard(data: cat),
                  ),
                ),
              )
              .toList(),
    );
  }

  Widget _buildTodaysFocusHeader() {
    final filters = ['All', 'Pending', 'Completed'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text("Today's Focus", style: AppTypography.h3),
        Row(
          children:
              filters.asMap().entries.map((entry) {
                final isSelected = _selectedFilter == entry.key;
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedFilter = entry.key),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? AppColors.primary
                                : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(20),
                        border:
                            isSelected
                                ? null
                                : Border.all(color: AppColors.cardBorder),
                      ),
                      child: Text(
                        entry.value,
                        style: AppTypography.bodySmall.copyWith(
                          color:
                              isSelected
                                  ? Colors.white
                                  : AppColors.textSecondary,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  List<Widget> _buildTaskList() {
    return _tasks.map((task) => _TaskTile(task: task)).toList();
  }

  // ═══════════════════════════════════════════════
  // RIGHT CONTENT
  // ═══════════════════════════════════════════════

  Widget _buildRightContent() {
    return ListView(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      children: [
        _buildAnalyticsCard(),
        const SizedBox(height: 16),
        _buildStreakCard(),
        const SizedBox(height: 16),
        _buildUpcomingCard(),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildAnalyticsCard() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Task Analytics', style: AppTypography.h3),
          const SizedBox(height: 20),
          // Circular chart
          Center(
            child: SizedBox(
              width: 140,
              height: 140,
              child: CustomPaint(
                painter: _DonutChartPainter(percentage: 0.74),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '74%',
                        style: AppTypography.h2.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Done',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Stats
          _buildStatRow(
            color: AppColors.primary,
            label: 'Completed',
            value: '12',
          ),
          const SizedBox(height: 8),
          _buildStatRow(
            color: const Color(0xFFEC4899),
            label: 'Pending',
            value: '4',
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow({
    required Color color,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: AppTypography.bodyMedium)),
        Text(value, style: AppTypography.labelLarge.copyWith(fontSize: 16)),
      ],
    );
  }

  Widget _buildStreakCard() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              color: Color(0xFFF59E0B),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '12 Day Streak',
                style: AppTypography.labelLarge.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 2),
              Text('Keep it up!', style: AppTypography.bodySmall),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingCard() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'UPCOMING',
            style: AppTypography.labelSmall.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          _UpcomingEvent(
            month: 'OCT',
            day: '24',
            title: 'Exam Prep',
            time: '10:00 AM - 12:00 PM',
          ),
          const SizedBox(height: 12),
          _UpcomingEvent(
            month: 'OCT',
            day: '25',
            title: 'Project Meet',
            time: '2:00 PM - 3:00 PM',
          ),
        ],
      ),
    );
  }

  // ── Dialog ──
  void _showAddTaskDialog() {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text('New Task', style: AppTypography.h3),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(hintText: 'Task title'),
                  style: AppTypography.bodyLarge,
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Description (optional)',
                  ),
                  style: AppTypography.bodyLarge,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Add'),
              ),
            ],
          ),
    );
  }
}

// ═══════════════════════════════════════════════════
// PRIVATE WIDGETS
// ═══════════════════════════════════════════════════

// ── Category Card ──
class _CategoryCard extends StatelessWidget {
  final _CategoryData data;
  const _CategoryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: data.color.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(data.icon, color: data.color, size: 22),
              ),
              Icon(Icons.more_horiz, color: AppColors.textTertiary, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            data.name,
            style: AppTypography.labelLarge.copyWith(fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            '${data.pending} TASKS PENDING',
            style: AppTypography.labelSmall.copyWith(fontSize: 10),
          ),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.6,
              minHeight: 4,
              backgroundColor: AppColors.surfaceLight,
              valueColor: AlwaysStoppedAnimation<Color>(data.color),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Task Tile ──
class _TaskTile extends StatelessWidget {
  final _DemoTask task;
  const _TaskTile({required this.task});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Checkbox circle
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.textTertiary, width: 2),
              ),
            ),
            const SizedBox(width: 16),
            // Title + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: AppTypography.labelLarge.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 12,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(task.subtitle, style: AppTypography.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
            // Priority badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: task.priorityColor.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: task.priorityColor.withAlpha(120)),
              ),
              child: Text(
                task.priority,
                style: AppTypography.bodySmall.copyWith(
                  color: task.priorityColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Pomodoro count
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 8, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  '${task.pomodoros} Pomodoro${task.pomodoros > 1 ? 's' : ''}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Upcoming Event ──
class _UpcomingEvent extends StatelessWidget {
  final String month;
  final String day;
  final String title;
  final String time;

  const _UpcomingEvent({
    required this.month,
    required this.day,
    required this.title,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Date badge
        Container(
          width: 48,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            children: [
              Text(
                month,
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: 1,
                ),
              ),
              Text(day, style: AppTypography.h3.copyWith(fontSize: 18)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTypography.labelLarge.copyWith(fontSize: 14)),
            const SizedBox(height: 2),
            Text(time, style: AppTypography.bodySmall),
          ],
        ),
      ],
    );
  }
}

// ── Donut Chart Painter ──
class _DonutChartPainter extends CustomPainter {
  final double percentage;
  _DonutChartPainter({required this.percentage});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const strokeWidth = 12.0;

    // Background arc
    final bgPaint =
        Paint()
          ..color = AppColors.surfaceLight
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc — gradient-like sweep
    final progressPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..shader = SweepGradient(
            startAngle: -math.pi / 2,
            endAngle: 3 * math.pi / 2,
            colors: const [
              Color(0xFF3B82F6),
              Color(0xFF06B6D4),
              Color(0xFF22C55E),
            ],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * percentage,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Data Models ──
class _DemoTask {
  final String title;
  final String subtitle;
  final String priority;
  final Color priorityColor;
  final int pomodoros;

  _DemoTask({
    required this.title,
    required this.subtitle,
    required this.priority,
    required this.priorityColor,
    required this.pomodoros,
  });
}

class _CategoryData {
  final String name;
  final IconData icon;
  final int pending;
  final Color color;

  _CategoryData({
    required this.name,
    required this.icon,
    required this.pending,
    required this.color,
  });
}
