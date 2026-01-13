import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/event.dart';
import '../theme.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  String _currentFilter = 'all';
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedMonth = DateTime.now();

  List<Event> _filterEvents(List<Event> events) {
    var filtered = events;

    if (_currentFilter != 'all') {
      filtered = filtered.where((e) => e.category == _currentFilter).toList();
    }

    filtered.sort((a, b) => a.startTime.compareTo(b.startTime));

    return filtered;
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'school':
        return NexusTheme.accent1;
      case 'training':
        return NexusTheme.trainingColor;
      case 'work':
        return NexusTheme.warning;
      case 'personal':
      default:
        return NexusTheme.accent3;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final filteredEvents = _filterEvents(provider.events);

        final eventsByDate = <String, List<Event>>{};
        for (final event in filteredEvents) {
          final dateKey = DateFormat('yyyy-MM-dd').format(event.startTime);
          eventsByDate.putIfAbsent(dateKey, () => []).add(event);
        }

        final datesWithEvents = provider.events.map(
          (e) => DateFormat('yyyy-MM-dd').format(e.startTime)
        ).toSet();

        final sortedDates = eventsByDate.keys.toList()..sort();

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
                              'Kalender',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Deine Termine im Überblick',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: isDark ? NexusTheme.darkTextMuted : NexusTheme.lightTextMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: () => showAddEventDialog(context),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Neuer Termin'),
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
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? NexusTheme.darkCard : NexusTheme.lightCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? NexusTheme.darkBorder : NexusTheme.lightBorder,
                    ),
                  ),
                  child: _buildMiniCalendar(context, datesWithEvents),
                ),
              ),

              SliverToBoxAdapter(
                child: Container(
                  height: 44,
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildFilterChip('all', 'Alle'),
                      _buildFilterChip('school', 'Schule'),
                      _buildFilterChip('training', 'Training'),
                      _buildFilterChip('personal', 'Privat'),
                      _buildFilterChip('work', 'Arbeit'),
                    ],
                  ),
                ),
              ),

              if (filteredEvents.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(context),
                )
              else

                for (final dateKey in sortedDates) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: _DateHeader(date: DateTime.parse(dateKey)),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final event = eventsByDate[dateKey]![index];
                          return _EventCard(
                            event: event,
                            categoryColor: _getCategoryColor(event.category),
                            onDelete: () => provider.deleteEvent(event.id),
                            onEdit: () => _showEditEventDialog(context, event),
                          );
                        },
                        childCount: eventsByDate[dateKey]!.length,
                      ),
                    ),
                  ),
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

  Widget _buildMiniCalendar(BuildContext context, Set<String> datesWithEvents) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final startingWeekday = firstDayOfMonth.weekday;

    return Column(
      children: [

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () {
                setState(() {
                  _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
                });
              },
            ),
            Text(
              DateFormat('MMMM yyyy', 'de_DE').format(_focusedMonth),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                setState(() {
                  _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 8),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So']
              .map((day) => SizedBox(
                    width: 36,
                    child: Text(
                      day,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? NexusTheme.darkTextMuted : NexusTheme.lightTextMuted,
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1,
          ),
          itemCount: 42,
          itemBuilder: (context, index) {
            final dayOffset = index - startingWeekday + 2;
            if (dayOffset < 1 || dayOffset > daysInMonth) {
              return const SizedBox();
            }

            final date = DateTime(_focusedMonth.year, _focusedMonth.month, dayOffset);
            final dateKey = DateFormat('yyyy-MM-dd').format(date);
            final hasEvents = datesWithEvents.contains(dateKey);
            final isToday = DateFormat('yyyy-MM-dd').format(DateTime.now()) == dateKey;
            final isSelected = DateFormat('yyyy-MM-dd').format(_selectedDate) == dateKey;

            return GestureDetector(
              onTap: () => setState(() => _selectedDate = date),
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? NexusTheme.primaryColor
                      : isToday
                          ? NexusTheme.primaryColor.withOpacity(0.1)
                          : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      '$dayOffset',
                      style: TextStyle(
                        fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? Colors.white
                            : isToday
                                ? NexusTheme.primaryColor
                                : null,
                      ),
                    ),
                    if (hasEvents)
                      Positioned(
                        bottom: 4,
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : NexusTheme.accent2,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_available,
              size: 64,
              color: NexusTheme.primaryColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _currentFilter == 'all'
                  ? 'Keine Termine vorhanden'
                  : 'Keine ${Event.categories[_currentFilter]}-Termine',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => showAddEventDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Termin hinzufügen'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditEventDialog(BuildContext context, Event event) {
    showDialog(
      context: context,
      builder: (context) => _EventDialog(event: event),
    );
  }
}

class _DateHeader extends StatelessWidget {
  final DateTime date;

  const _DateHeader({required this.date});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDate = DateTime(date.year, date.month, date.day);

    String label;
    if (eventDate == today) {
      label = 'Heute';
    } else if (eventDate == today.add(const Duration(days: 1))) {
      label = 'Morgen';
    } else {
      label = DateFormat('EEEE, d. MMMM', 'de_DE').format(date);
    }

    return Text(
      label,
      style: TextStyle(
        color: NexusTheme.primaryColor,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final Event event;
  final Color categoryColor;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _EventCard({
    required this.event,
    required this.categoryColor,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dismissible(
      key: Key(event.id),
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
          child: Row(
            children: [

              Container(
                width: 4,
                height: 70,
                decoration: BoxDecoration(
                  color: categoryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              event.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: categoryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              Event.categories[event.category] ?? event.category,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: categoryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: isDark ? NexusTheme.darkTextMuted : NexusTheme.lightTextMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            event.timeRange,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? NexusTheme.darkTextMuted : NexusTheme.lightTextMuted,
                            ),
                          ),
                        ],
                      ),
                      if (event.location != null && event.location!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: isDark ? NexusTheme.darkTextMuted : NexusTheme.lightTextMuted,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                event.location!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? NexusTheme.darkTextMuted : NexusTheme.lightTextMuted,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isDark ? NexusTheme.darkTextMuted : NexusTheme.lightTextMuted,
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventDialog extends StatefulWidget {
  final Event? event;

  const _EventDialog({this.event});

  @override
  State<_EventDialog> createState() => _EventDialogState();
}

class _EventDialogState extends State<_EventDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late DateTime _startTime;
  late DateTime _endTime;
  bool _allDay = false;
  String _category = 'personal';

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event?.title ?? '');
    _descriptionController = TextEditingController(text: widget.event?.description ?? '');
    _locationController = TextEditingController(text: widget.event?.location ?? '');
    _startTime = widget.event?.startTime ?? DateTime.now();
    _endTime = widget.event?.endTime ?? DateTime.now().add(const Duration(hours: 1));
    _allDay = widget.event?.allDay ?? false;
    _category = widget.event?.category ?? 'personal';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.event != null ? 'Termin bearbeiten' : 'Neuer Termin'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Titel',
                hintText: 'Was steht an?',
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
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Ort (optional)',
                hintText: 'Wo findet es statt?',
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(
                labelText: 'Kategorie',
                prefixIcon: Icon(Icons.category),
              ),
              items: Event.categories.entries.map((e) =>
                DropdownMenuItem(value: e.key, child: Text(e.value))
              ).toList(),
              onChanged: (value) => setState(() => _category = value!),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Ganztags'),
              value: _allDay,
              onChanged: (value) => setState(() => _allDay = value),
              contentPadding: EdgeInsets.zero,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.access_time),
              title: const Text('Start'),
              subtitle: Text(
                _allDay
                    ? DateFormat('dd.MM.yyyy').format(_startTime)
                    : DateFormat('dd.MM.yyyy HH:mm').format(_startTime),
              ),
              onTap: () => _selectDateTime(true),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.access_time_filled),
              title: const Text('Ende'),
              subtitle: Text(
                _allDay
                    ? DateFormat('dd.MM.yyyy').format(_endTime)
                    : DateFormat('dd.MM.yyyy HH:mm').format(_endTime),
              ),
              onTap: () => _selectDateTime(false),
            ),
          ],
        ),
      ),
      actions: [
        if (widget.event != null)
          TextButton(
            onPressed: () {
              context.read<AppProvider>().deleteEvent(widget.event!.id);
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

  Future<void> _selectDateTime(bool isStart) async {
    final initialDate = isStart ? _startTime : _endTime;

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );

    if (date == null || !mounted) return;

    if (_allDay) {
      setState(() {
        if (isStart) {
          _startTime = DateTime(date.year, date.month, date.day);
        } else {
          _endTime = DateTime(date.year, date.month, date.day, 23, 59);
        }
      });
    } else {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );

      if (time != null && mounted) {
        setState(() {
          final newDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
          if (isStart) {
            _startTime = newDateTime;
            if (_endTime.isBefore(_startTime)) {
              _endTime = _startTime.add(const Duration(hours: 1));
            }
          } else {
            _endTime = newDateTime;
          }
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

    if (widget.event != null) {
      provider.updateEvent(widget.event!.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        startTime: _startTime,
        endTime: _endTime,
        allDay: _allDay,
        category: _category,
      ));
    } else {
      provider.addEvent(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        startTime: _startTime,
        endTime: _endTime,
        allDay: _allDay,
        category: _category,
      );
    }

    Navigator.pop(context);
  }
}

void showAddEventDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const _EventDialog(),
  );
}
