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

class _CalendarScreenState extends State<CalendarScreen> with SingleTickerProviderStateMixin {
  String _currentFilter = 'all';
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedMonth = DateTime.now();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<Event> _filterEvents(List<Event> events) {
    var filtered = events;

    if (_currentFilter != 'all') {
      filtered = filtered.where((e) => e.category == _currentFilter).toList();
    }

    filtered.sort((a, b) => a.startTime.compareTo(b.startTime));

    return filtered;
  }

  List<Event> _getEventsForDate(List<Event> events, DateTime date) {
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    return events.where((e) {
      final eventStart = DateFormat('yyyy-MM-dd').format(e.startTime);
      final eventEnd = DateFormat('yyyy-MM-dd').format(e.endTime);
      final checkDate = DateFormat('yyyy-MM-dd').format(date);

      return checkDate.compareTo(eventStart) >= 0 && checkDate.compareTo(eventEnd) <= 0;
    }).toList();
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'school':
        return NexusTheme.accent1;
      case 'training':
        return NexusTheme.trainingColor;
      case 'work':
        return NexusTheme.warning;
      case 'holiday':
        return const Color(0xFFEF4444);
      case 'vacation':
        return const Color(0xFF22C55E);
      case 'personal':
      default:
        return NexusTheme.accent3;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'school':
        return Icons.school_rounded;
      case 'training':
        return Icons.fitness_center_rounded;
      case 'work':
        return Icons.work_rounded;
      case 'holiday':
        return Icons.celebration_rounded;
      case 'vacation':
        return Icons.beach_access_rounded;
      case 'personal':
      default:
        return Icons.person_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final filteredEvents = _filterEvents(provider.events);
        final selectedDayEvents = _getEventsForDate(filteredEvents, _selectedDate);

        return FadeTransition(
          opacity: _fadeAnimation,
          child: RefreshIndicator(
            onRefresh: provider.refresh,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _buildHeader(context, isDark),
                ),

                SliverToBoxAdapter(
                  child: _buildCalendarCard(context, isDark, provider.events, isTablet),
                ),

                SliverToBoxAdapter(
                  child: _buildCategoryFilters(isDark),
                ),

                SliverToBoxAdapter(
                  child: _buildSelectedDayHeader(isDark, selectedDayEvents.length),
                ),

                if (selectedDayEvents.isEmpty)
                  SliverToBoxAdapter(
                    child: _buildEmptyDayState(context, isDark),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final event = selectedDayEvents[index];
                          return _ModernEventCard(
                            event: event,
                            categoryColor: _getCategoryColor(event.category),
                            categoryIcon: _getCategoryIcon(event.category),
                            onDelete: () => provider.deleteEvent(event.id),
                            onEdit: () => _showEditEventDialog(context, event),
                            isFirst: index == 0,
                            isLast: index == selectedDayEvents.length - 1,
                          );
                        },
                        childCount: selectedDayEvents.length,
                      ),
                    ),
                  ),

                if (!_isToday(_selectedDate))
                  SliverToBoxAdapter(
                    child: _buildUpcomingSection(context, isDark, filteredEvents),
                  ),

                const SliverPadding(
                  padding: EdgeInsets.only(bottom: 100),
                  sliver: SliverToBoxAdapter(child: SizedBox()),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
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
                const SizedBox(height: 2),
                Text(
                  DateFormat('EEEE, d. MMMM yyyy', 'de_DE').format(DateTime.now()),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark ? NexusTheme.darkTextMuted : NexusTheme.lightTextMuted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [NexusTheme.primaryColor, NexusTheme.accent1],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: NexusTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => showAddEventDialog(context),
                borderRadius: BorderRadius.circular(14),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 6),
                      Text(
                        'Neu',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarCard(BuildContext context, bool isDark, List<Event> allEvents, bool isTablet) {
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final startingWeekday = firstDayOfMonth.weekday;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      decoration: BoxDecoration(
        color: isDark ? NexusTheme.darkCard : NexusTheme.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? NexusTheme.darkBorder : NexusTheme.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
            child: Row(
              children: [
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.chevron_left_rounded, size: 20),
                  ),
                  onPressed: () {
                    setState(() {
                      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
                    });
                  },
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showMonthPicker(context),
                    child: Column(
                      children: [
                        Text(
                          DateFormat('MMMM', 'de_DE').format(_focusedMonth),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          '${_focusedMonth.year}',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? NexusTheme.darkTextMuted : NexusTheme.lightTextMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.chevron_right_rounded, size: 20),
                  ),
                  onPressed: () {
                    setState(() {
                      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
                    });
                  },
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So']
                  .map((day) => SizedBox(
                        width: isTablet ? 50 : 40,
                        child: Text(
                          day,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: day == 'Sa' || day == 'So'
                                ? NexusTheme.primaryColor.withOpacity(0.7)
                                : (isDark ? NexusTheme.darkTextMuted : NexusTheme.lightTextMuted),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),

          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: isTablet ? 1.2 : 1.0,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemCount: 42,
              itemBuilder: (context, index) {
                final dayOffset = index - startingWeekday + 2;
                if (dayOffset < 1 || dayOffset > daysInMonth) {
                  return const SizedBox();
                }

                final date = DateTime(_focusedMonth.year, _focusedMonth.month, dayOffset);
                final dayEvents = _getEventsForDate(allEvents, date);
                final isToday = _isToday(date);
                final isSelected = _isSameDay(date, _selectedDate);
                final isWeekend = date.weekday == 6 || date.weekday == 7;

                return _CalendarDay(
                  day: dayOffset,
                  events: dayEvents,
                  isToday: isToday,
                  isSelected: isSelected,
                  isWeekend: isWeekend,
                  isDark: isDark,
                  onTap: () => setState(() => _selectedDate = date),
                  getCategoryColor: _getCategoryColor,
                );
              },
            ),
          ),

          if (!_isSameMonth(_focusedMonth, DateTime.now()))
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _focusedMonth = DateTime.now();
                    _selectedDate = DateTime.now();
                  });
                },
                icon: const Icon(Icons.today_rounded, size: 18),
                label: const Text('Heute'),
                style: TextButton.styleFrom(
                  foregroundColor: NexusTheme.primaryColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilters(bool isDark) {
    final categories = [
      ('all', 'Alle', Icons.apps_rounded),
      ('school', 'Schule', Icons.school_rounded),
      ('training', 'Training', Icons.fitness_center_rounded),
      ('personal', 'Privat', Icons.person_rounded),
      ('work', 'Arbeit', Icons.work_rounded),
      ('holiday', 'Feiertage', Icons.celebration_rounded),
      ('vacation', 'Ferien', Icons.beach_access_rounded),
    ];

    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final (filter, label, icon) = categories[index];
          final isSelected = _currentFilter == filter;
          final color = filter == 'all'
              ? NexusTheme.primaryColor
              : _getCategoryColor(filter);

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() => _currentFilter = filter),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withOpacity(0.15)
                          : (isDark ? NexusTheme.darkCard : NexusTheme.lightCard),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? color
                            : (isDark ? NexusTheme.darkBorder : NexusTheme.lightBorder),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: 16,
                          color: isSelected ? color : (isDark ? NexusTheme.darkTextMuted : NexusTheme.lightTextMuted),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected ? color : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSelectedDayHeader(bool isDark, int eventCount) {
    final isToday = _isToday(_selectedDate);
    final isTomorrow = _isSameDay(_selectedDate, DateTime.now().add(const Duration(days: 1)));

    String label;
    if (isToday) {
      label = 'Heute';
    } else if (isTomorrow) {
      label = 'Morgen';
    } else {
      label = DateFormat('EEEE, d. MMMM', 'de_DE').format(_selectedDate);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: NexusTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.event_rounded,
              color: NexusTheme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  eventCount == 0
                      ? 'Keine Termine'
                      : '$eventCount ${eventCount == 1 ? 'Termin' : 'Termine'}',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? NexusTheme.darkTextMuted : NexusTheme.lightTextMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDayState(BuildContext context, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? NexusTheme.darkCard : NexusTheme.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? NexusTheme.darkBorder : NexusTheme.lightBorder,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: NexusTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.event_available_rounded,
              size: 40,
              color: NexusTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Keine Termine',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'An diesem Tag ist nichts geplant',
            style: TextStyle(
              color: isDark ? NexusTheme.darkTextMuted : NexusTheme.lightTextMuted,
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => showAddEventDialog(context),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Termin hinzufugen'),
            style: OutlinedButton.styleFrom(
              foregroundColor: NexusTheme.primaryColor,
              side: BorderSide(color: NexusTheme.primaryColor),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingSection(BuildContext context, bool isDark, List<Event> events) {
    final now = DateTime.now();
    final upcoming = events
        .where((e) => e.startTime.isAfter(now))
        .take(3)
        .toList();

    if (upcoming.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.upcoming_rounded,
                color: NexusTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Kommende Termine',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...upcoming.map((event) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _UpcomingEventCard(
              event: event,
              categoryColor: _getCategoryColor(event.category),
              categoryIcon: _getCategoryIcon(event.category),
              isDark: isDark,
              onTap: () {
                setState(() {
                  _selectedDate = event.startTime;
                  _focusedMonth = DateTime(event.startTime.year, event.startTime.month);
                });
              },
            ),
          )),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  void _showMonthPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _MonthPickerSheet(
        selectedMonth: _focusedMonth,
        onMonthSelected: (month) {
          setState(() => _focusedMonth = month);
          Navigator.pop(context);
        },
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

class _CalendarDay extends StatelessWidget {
  final int day;
  final List<Event> events;
  final bool isToday;
  final bool isSelected;
  final bool isWeekend;
  final bool isDark;
  final VoidCallback onTap;
  final Color Function(String) getCategoryColor;

  const _CalendarDay({
    required this.day,
    required this.events,
    required this.isToday,
    required this.isSelected,
    required this.isWeekend,
    required this.isDark,
    required this.onTap,
    required this.getCategoryColor,
  });

  @override
  Widget build(BuildContext context) {
    final eventColors = events
        .map((e) => getCategoryColor(e.category))
        .toSet()
        .take(3)
        .toList();

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isSelected
              ? NexusTheme.primaryColor
              : isToday
                  ? NexusTheme.primaryColor.withOpacity(0.1)
                  : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              '$day',
              style: TextStyle(
                fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
                color: isSelected
                    ? Colors.white
                    : isToday
                        ? NexusTheme.primaryColor
                        : isWeekend
                            ? NexusTheme.primaryColor.withOpacity(0.6)
                            : null,
              ),
            ),
            if (eventColors.isNotEmpty)
              Positioned(
                bottom: 4,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: eventColors.map((color) => Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : color,
                      shape: BoxShape.circle,
                    ),
                  )).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ModernEventCard extends StatelessWidget {
  final Event event;
  final Color categoryColor;
  final IconData categoryIcon;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final bool isFirst;
  final bool isLast;

  const _ModernEventCard({
    required this.event,
    required this.categoryColor,
    required this.categoryIcon,
    required this.onDelete,
    required this.onEdit,
    required this.isFirst,
    required this.isLast,
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
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: NexusTheme.danger,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isDark ? NexusTheme.darkCard : NexusTheme.lightCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? NexusTheme.darkBorder : NexusTheme.lightBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: categoryColor.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onEdit,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      categoryIcon,
                      color: categoryColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 14,
                              color: isDark ? NexusTheme.darkTextMuted : NexusTheme.lightTextMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              event.allDay ? 'Ganztags' : event.timeRange,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? NexusTheme.darkTextMuted : NexusTheme.lightTextMuted,
                              ),
                            ),
                          ],
                        ),
                        if (event.location != null && event.location!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_rounded,
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      Event.categories[event.category] ?? event.category,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: categoryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UpcomingEventCard extends StatelessWidget {
  final Event event;
  final Color categoryColor;
  final IconData categoryIcon;
  final bool isDark;
  final VoidCallback onTap;

  const _UpcomingEventCard({
    required this.event,
    required this.categoryColor,
    required this.categoryIcon,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? NexusTheme.darkCard : NexusTheme.lightCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? NexusTheme.darkBorder : NexusTheme.lightBorder,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: categoryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      DateFormat('EEEE, d. MMM', 'de_DE').format(event.startTime),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? NexusTheme.darkTextMuted : NexusTheme.lightTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: isDark ? NexusTheme.darkTextMuted : NexusTheme.lightTextMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthPickerSheet extends StatelessWidget {
  final DateTime selectedMonth;
  final Function(DateTime) onMonthSelected;

  const _MonthPickerSheet({
    required this.selectedMonth,
    required this.onMonthSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentYear = DateTime.now().year;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? NexusTheme.darkCard : NexusTheme.lightCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Monat auswahlen',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 2.5,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                final month = DateTime(currentYear, index + 1);
                final isSelected = selectedMonth.month == index + 1 &&
                                   selectedMonth.year == currentYear;

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onMonthSelected(month),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? NexusTheme.primaryColor
                            : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        DateFormat('MMM', 'de_DE').format(month),
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white : null,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: NexusTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.event != null ? Icons.edit_rounded : Icons.add_rounded,
                      color: NexusTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.event != null ? 'Termin bearbeiten' : 'Neuer Termin',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Titel',
                  hintText: 'Was steht an?',
                  prefixIcon: const Icon(Icons.title_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Beschreibung (optional)',
                  hintText: 'Weitere Details...',
                  prefixIcon: const Icon(Icons.description_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Ort (optional)',
                  hintText: 'Wo findet es statt?',
                  prefixIcon: const Icon(Icons.location_on_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _category,
                decoration: InputDecoration(
                  labelText: 'Kategorie',
                  prefixIcon: const Icon(Icons.category_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: Event.categories.entries.map((e) =>
                  DropdownMenuItem(value: e.key, child: Text(e.value))
                ).toList(),
                onChanged: (value) => setState(() => _category = value!),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isDark ? NexusTheme.darkBorder : NexusTheme.lightBorder,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SwitchListTile(
                  title: const Text('Ganztags'),
                  value: _allDay,
                  onChanged: (value) => setState(() => _allDay = value),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _DateTimeButton(
                      label: 'Start',
                      dateTime: _startTime,
                      allDay: _allDay,
                      onTap: () => _selectDateTime(true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DateTimeButton(
                      label: 'Ende',
                      dateTime: _endTime,
                      allDay: _allDay,
                      onTap: () => _selectDateTime(false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  if (widget.event != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          context.read<AppProvider>().deleteEvent(widget.event!.id);
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.delete_rounded),
                        label: const Text('Loschen'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: NexusTheme.danger,
                          side: BorderSide(color: NexusTheme.danger),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  if (widget.event != null) const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Speichern'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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

class _DateTimeButton extends StatelessWidget {
  final String label;
  final DateTime dateTime;
  final bool allDay;
  final VoidCallback onTap;

  const _DateTimeButton({
    required this.label,
    required this.dateTime,
    required this.allDay,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: isDark ? NexusTheme.darkBorder : NexusTheme.lightBorder,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? NexusTheme.darkTextMuted : NexusTheme.lightTextMuted,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('dd.MM.yyyy').format(dateTime),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (!allDay)
                Text(
                  DateFormat('HH:mm').format(dateTime),
                  style: TextStyle(
                    fontSize: 13,
                    color: NexusTheme.primaryColor,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

void showAddEventDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const _EventDialog(),
  );
}
