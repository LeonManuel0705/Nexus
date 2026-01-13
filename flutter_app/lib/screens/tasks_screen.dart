import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/task.dart';
import '../theme.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  String _currentFilter = 'today';

  List<Task> _filterTasks(List<Task> tasks) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endOfWeek = today.add(Duration(days: 7 - today.weekday));

    switch (_currentFilter) {
      case 'today':
        return tasks.where((t) {
          if (t.completed) return false;
          if (t.dueDate == null) return false;
          final dueDay = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
          return dueDay.isAtSameMomentAs(today) || dueDay.isBefore(today);
        }).toList();
      case 'week':
        return tasks.where((t) {
          if (t.completed) return false;
          if (t.dueDate == null) return false;
          final dueDay = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
          return dueDay.isAfter(today) && !dueDay.isAfter(endOfWeek);
        }).toList();
      case 'later':
        return tasks.where((t) {
          if (t.completed) return false;
          if (t.dueDate == null) return true;
          final dueDay = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
          return dueDay.isAfter(endOfWeek);
        }).toList();
      case 'completed':
        return tasks.where((t) => t.completed).toList();
      case 'all':
      default:
        return tasks.where((t) => !t.completed).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final filteredTasks = _filterTasks(provider.tasks);

        final highPriority = filteredTasks.where((t) => t.priority == 'high').toList();
        final normalPriority = filteredTasks.where((t) => t.priority == 'medium').toList();
        final lowPriority = filteredTasks.where((t) => t.priority == 'low').toList();

        return RefreshIndicator(
          onRefresh: provider.refresh,
          child: CustomScrollView(
            slivers: [

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Aufgaben',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Verwalte deine To-Dos',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: isDark ? NexusTheme.darkTextMuted : NexusTheme.lightTextMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: () => showAddTaskDialog(context),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Neue Aufgabe'),
                        style: FilledButton.styleFrom(
                          backgroundColor: NexusTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Container(
                  height: 44,
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildFilterChip('today', 'Heute'),
                      _buildFilterChip('week', 'Diese Woche'),
                      _buildFilterChip('later', 'Später'),
                      _buildFilterChip('all', 'Alle'),
                      _buildFilterChip('completed', 'Erledigt'),
                    ],
                  ),
                ),
              ),

              if (filteredTasks.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(context),
                )
              else ...[
                if (highPriority.isNotEmpty)
                  _buildTaskGroup(context, 'Hohe Priorität', highPriority, NexusTheme.danger, provider),
                if (normalPriority.isNotEmpty)
                  _buildTaskGroup(context, 'Normal', normalPriority, NexusTheme.primaryColor, provider),
                if (lowPriority.isNotEmpty)
                  _buildTaskGroup(context, 'Niedrige Priorität', lowPriority, NexusTheme.success, provider),
              ],

              const SliverPadding(
                padding: EdgeInsets.only(bottom: 100),
                sliver: SliverToBoxAdapter(child: SizedBox()),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String filter, String label) {
    final isSelected = _currentFilter == filter;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _currentFilter = filter),
        selectedColor: NexusTheme.primaryColor.withOpacity(0.2),
        checkmarkColor: NexusTheme.primaryColor,
        labelStyle: TextStyle(
          color: isSelected ? NexusTheme.primaryColor : null,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final messages = {
      'today': 'Keine Aufgaben für heute',
      'week': 'Keine Aufgaben diese Woche',
      'later': 'Keine späteren Aufgaben',
      'completed': 'Keine erledigten Aufgaben',
      'all': 'Keine Aufgaben vorhanden',
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.task_alt,
              size: 64,
              color: NexusTheme.primaryColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              messages[_currentFilter] ?? 'Keine Aufgaben',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => showAddTaskDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Aufgabe hinzufügen'),
            ),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildTaskGroup(
    BuildContext context,
    String title,
    List<Task> tasks,
    Color color,
    AppProvider provider,
  ) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 4),
              child: Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            ...tasks.map((task) => _TaskListItem(
              task: task,
              onToggle: () => provider.toggleTaskComplete(task.id),
              onDelete: () => provider.deleteTask(task.id),
              onEdit: () => _showEditTaskDialog(context, task),
            )),
          ],
        ),
      ),
    );
  }

  void _showEditTaskDialog(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (context) => _TaskDialog(task: task),
    );
  }
}

class _TaskListItem extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _TaskListItem({
    required this.task,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });

  Color get priorityColor {
    switch (task.priority) {
      case 'high':
        return NexusTheme.danger;
      case 'medium':
        return NexusTheme.warning;
      default:
        return NexusTheme.success;
    }
  }

  Color get categoryColor {
    switch (task.category) {
      case 'school':
        return NexusTheme.accent1;
      case 'training':
        return NexusTheme.trainingColor;
      case 'project':
        return NexusTheme.projectsColor;
      case 'personal':
        return NexusTheme.accent3;
      default:
        return NexusTheme.gray;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOverdue = task.dueDate != null &&
        task.dueDate!.isBefore(DateTime.now()) &&
        !task.completed;

    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: NexusTheme.danger,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isDark ? NexusTheme.darkCard : NexusTheme.lightCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? NexusTheme.darkBorder : NexusTheme.lightBorder,
          ),
        ),
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [

                GestureDetector(
                  onTap: onToggle,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: task.completed ? NexusTheme.success : Colors.transparent,
                      border: Border.all(
                        color: task.completed ? NexusTheme.success : priorityColor,
                        width: 2,
                      ),
                    ),
                    child: task.completed
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          decoration: task.completed ? TextDecoration.lineThrough : null,
                          color: task.completed
                              ? (isDark ? NexusTheme.darkTextMuted : NexusTheme.lightTextMuted)
                              : null,
                        ),
                      ),
                      if (task.description != null && task.description!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          task.description!,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? NexusTheme.darkTextMuted : NexusTheme.lightTextMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (task.dueDate != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isOverdue
                                    ? NexusTheme.danger.withOpacity(0.1)
                                    : (isDark ? NexusTheme.darkSurface : NexusTheme.lightSurface),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _formatDueDate(task.dueDate!),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: isOverdue ? NexusTheme.danger : null,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: categoryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              Task.categories[task.category] ?? task.category,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: categoryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Icon(
                  Icons.chevron_right,
                  color: isDark ? NexusTheme.darkTextMuted : NexusTheme.lightTextMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDueDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dueDay = DateTime(date.year, date.month, date.day);

    if (dueDay.isAtSameMomentAs(today)) {
      return 'Heute';
    } else if (dueDay.isAtSameMomentAs(tomorrow)) {
      return 'Morgen';
    } else if (dueDay.isBefore(today)) {
      return 'Überfällig';
    } else {
      return DateFormat('dd. MMM', 'de_DE').format(date);
    }
  }
}

class _TaskDialog extends StatefulWidget {
  final Task? task;

  const _TaskDialog({this.task});

  @override
  State<_TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends State<_TaskDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  DateTime? _dueDate;
  String _priority = 'medium';
  String _category = 'general';

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(text: widget.task?.description ?? '');
    _dueDate = widget.task?.dueDate;
    _priority = widget.task?.priority ?? 'medium';
    _category = widget.task?.category ?? 'general';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.task != null ? 'Aufgabe bearbeiten' : 'Neue Aufgabe'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Titel',
                hintText: 'Was muss erledigt werden?',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Beschreibung (optional)',
                hintText: 'Weitere Details...',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: Text(_dueDate != null
                  ? DateFormat('dd.MM.yyyy HH:mm').format(_dueDate!)
                  : 'Fällig am'),
              trailing: _dueDate != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _dueDate = null),
                    )
                  : null,
              onTap: _selectDateTime,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _priority,
              decoration: const InputDecoration(
                labelText: 'Priorität',
                prefixIcon: Icon(Icons.flag),
              ),
              items: const [
                DropdownMenuItem(value: 'low', child: Text('Niedrig')),
                DropdownMenuItem(value: 'medium', child: Text('Normal')),
                DropdownMenuItem(value: 'high', child: Text('Hoch')),
              ],
              onChanged: (value) => setState(() => _priority = value!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(
                labelText: 'Kategorie',
                prefixIcon: Icon(Icons.category),
              ),
              items: Task.categories.entries.map((e) =>
                DropdownMenuItem(value: e.key, child: Text(e.value))
              ).toList(),
              onChanged: (value) => setState(() => _category = value!),
            ),
          ],
        ),
      ),
      actions: [
        if (widget.task != null)
          TextButton(
            onPressed: () {
              context.read<AppProvider>().deleteTask(widget.task!.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: NexusTheme.danger),
            child: const Text('Löschen'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Speichern'),
        ),
      ],
    );
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_dueDate ?? DateTime.now()),
      );

      if (time != null && mounted) {
        setState(() {
          _dueDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        });
      }
    }
  }

  void _save() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte Titel eingeben')),
      );
      return;
    }

    final provider = context.read<AppProvider>();

    if (widget.task != null) {
      provider.updateTask(widget.task!.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        dueDate: _dueDate,
        priority: _priority,
        category: _category,
      ));
    } else {
      provider.addTask(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        dueDate: _dueDate,
        priority: _priority,
        category: _category,
      );
    }

    Navigator.pop(context);
  }
}

void showAddTaskDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const _TaskDialog(),
  );
}
