import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _dailyAchievedController = TextEditingController();
  final _dailyGoodController = TextEditingController();
  final _dailyBetterController = TextEditingController();
  final _dailyFocusController = TextEditingController();
  final _dailyGratefulController = TextEditingController();
  int _dailyEnergy = 5;

  final _weeklyHighlightsController = TextEditingController();
  final _weeklyProgressController = TextEditingController();
  final _weeklyChallengesController = TextEditingController();
  final _weeklyLearningsController = TextEditingController();
  final _weeklyGoalsController = TextEditingController();

  List<ReviewEntry> _dailyReviews = [];
  List<WeeklyReviewEntry> _weeklyReviews = [];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _checkTodayReview();
    _checkThisWeekReview();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _dailyAchievedController.dispose();
    _dailyGoodController.dispose();
    _dailyBetterController.dispose();
    _dailyFocusController.dispose();
    _dailyGratefulController.dispose();
    _weeklyHighlightsController.dispose();
    _weeklyProgressController.dispose();
    _weeklyChallengesController.dispose();
    _weeklyLearningsController.dispose();
    _weeklyGoalsController.dispose();
    super.dispose();
  }

  void _checkTodayReview() {
    final today = DateTime.now();
    final todayReview = _dailyReviews.where((r) =>
        r.date.year == today.year &&
        r.date.month == today.month &&
        r.date.day == today.day).firstOrNull;

    if (todayReview != null) {
      _dailyAchievedController.text = todayReview.achieved;
      _dailyGoodController.text = todayReview.good;
      _dailyBetterController.text = todayReview.better;
      _dailyFocusController.text = todayReview.focus;
      _dailyGratefulController.text = todayReview.grateful;
      _dailyEnergy = todayReview.energy;
    }
  }

  void _checkThisWeekReview() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final thisWeekReview = _weeklyReviews.where((r) =>
        r.weekStart.year == weekStart.year &&
        r.weekStart.month == weekStart.month &&
        r.weekStart.day == weekStart.day).firstOrNull;

    if (thisWeekReview != null) {
      _weeklyHighlightsController.text = thisWeekReview.highlights;
      _weeklyProgressController.text = thisWeekReview.progress;
      _weeklyChallengesController.text = thisWeekReview.challenges;
      _weeklyLearningsController.text = thisWeekReview.learnings;
      _weeklyGoalsController.text = thisWeekReview.goals;
    }
  }

  Future<void> _saveDailyReview() async {
    if (_dailyAchievedController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte fülle mindestens das erste Feld aus')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final today = DateTime.now();
      final existingIndex = _dailyReviews.indexWhere((r) =>
          r.date.year == today.year &&
          r.date.month == today.month &&
          r.date.day == today.day);

      final review = ReviewEntry(
        id: existingIndex >= 0 ? _dailyReviews[existingIndex].id : DateTime.now().toString(),
        date: today,
        achieved: _dailyAchievedController.text,
        good: _dailyGoodController.text,
        better: _dailyBetterController.text,
        focus: _dailyFocusController.text,
        grateful: _dailyGratefulController.text,
        energy: _dailyEnergy,
      );

      if (existingIndex >= 0) {
        _dailyReviews[existingIndex] = review;
      } else {
        _dailyReviews.insert(0, review);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tages-Review gespeichert!'),
          backgroundColor: Colors.green,
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _saveWeeklyReview() async {
    if (_weeklyHighlightsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte fülle mindestens das erste Feld aus')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekNum = _getWeekNumber(now);

      final existingIndex = _weeklyReviews.indexWhere((r) =>
          r.weekStart.year == weekStart.year &&
          r.weekStart.month == weekStart.month &&
          r.weekStart.day == weekStart.day);

      final review = WeeklyReviewEntry(
        id: existingIndex >= 0 ? _weeklyReviews[existingIndex].id : DateTime.now().toString(),
        weekStart: weekStart,
        weekNumber: weekNum,
        highlights: _weeklyHighlightsController.text,
        progress: _weeklyProgressController.text,
        challenges: _weeklyChallengesController.text,
        learnings: _weeklyLearningsController.text,
        goals: _weeklyGoalsController.text,
      );

      if (existingIndex >= 0) {
        _weeklyReviews[existingIndex] = review;
      } else {
        _weeklyReviews.insert(0, review);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wochen-Review gespeichert!'),
          backgroundColor: Colors.green,
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysDiff = date.difference(firstDayOfYear).inDays;
    return ((daysDiff + firstDayOfYear.weekday - 1) / 7).ceil() + 1;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              gradient: const LinearGradient(
                colors: NexusTheme.primaryGradient,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: Colors.white,
            unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: 'Tages-Review'),
              Tab(text: 'Wochen-Review'),
              Tab(text: 'Verlauf'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildDailyReview(isDark),
              _buildWeeklyReview(isDark),
              _buildHistory(isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDailyReview(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: NexusTheme.primaryGradient,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.wb_sunny, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tages-Review',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : NexusTheme.lightText,
                      ),
                    ),
                    Text(
                      DateFormat('EEEE, d. MMMM yyyy', 'de_DE').format(DateTime.now()),
                      style: TextStyle(
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          _buildQuestionField(
            isDark: isDark,
            icon: Icons.check_circle_outline,
            question: 'Was hast du heute erreicht?',
            hint: 'Deine Erfolge und erledigten Aufgaben...',
            controller: _dailyAchievedController,
            color: NexusTheme.success,
          ),
          const SizedBox(height: 16),

          _buildQuestionField(
            isDark: isDark,
            icon: Icons.thumb_up_outlined,
            question: 'Was lief heute gut?',
            hint: 'Positive Momente und Erfahrungen...',
            controller: _dailyGoodController,
            color: NexusTheme.info,
          ),
          const SizedBox(height: 16),

          _buildQuestionField(
            isDark: isDark,
            icon: Icons.trending_up,
            question: 'Was kann morgen besser werden?',
            hint: 'Verbesserungsmöglichkeiten...',
            controller: _dailyBetterController,
            color: NexusTheme.warning,
          ),
          const SizedBox(height: 16),

          _buildQuestionField(
            isDark: isDark,
            icon: Icons.track_changes,
            question: 'Worauf fokussierst du dich morgen?',
            hint: 'Dein Hauptfokus für morgen...',
            controller: _dailyFocusController,
            color: NexusTheme.primaryColor,
          ),
          const SizedBox(height: 16),

          _buildQuestionField(
            isDark: isDark,
            icon: Icons.favorite_outline,
            question: 'Wofür bist du heute dankbar?',
            hint: 'Dinge, die du schätzt...',
            controller: _dailyGratefulController,
            color: NexusTheme.danger,
          ),
          const SizedBox(height: 24),

          _buildEnergySlider(isDark),
          const SizedBox(height: 24),

          _buildSaveButton(_saveDailyReview),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildWeeklyReview(bool isDark) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: NexusTheme.primaryGradient,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.date_range, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Wochen-Review',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : NexusTheme.lightText,
                      ),
                    ),
                    Text(
                      'KW ${_getWeekNumber(now)} (${DateFormat('d. MMM', 'de_DE').format(weekStart)} - ${DateFormat('d. MMM', 'de_DE').format(weekEnd)})',
                      style: TextStyle(
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          _buildQuestionField(
            isDark: isDark,
            icon: Icons.star_outline,
            question: 'Was waren deine Highlights dieser Woche?',
            hint: 'Die besten Momente...',
            controller: _weeklyHighlightsController,
            color: NexusTheme.warning,
          ),
          const SizedBox(height: 16),

          _buildQuestionField(
            isDark: isDark,
            icon: Icons.trending_up,
            question: 'Welche Fortschritte hast du gemacht?',
            hint: 'Deine Erfolge und Entwicklungen...',
            controller: _weeklyProgressController,
            color: NexusTheme.success,
          ),
          const SizedBox(height: 16),

          _buildQuestionField(
            isDark: isDark,
            icon: Icons.warning_amber_outlined,
            question: 'Was waren deine größten Herausforderungen?',
            hint: 'Schwierigkeiten und Hindernisse...',
            controller: _weeklyChallengesController,
            color: NexusTheme.danger,
          ),
          const SizedBox(height: 16),

          _buildQuestionField(
            isDark: isDark,
            icon: Icons.lightbulb_outline,
            question: 'Was hast du diese Woche gelernt?',
            hint: 'Neue Erkenntnisse und Einsichten...',
            controller: _weeklyLearningsController,
            color: NexusTheme.info,
          ),
          const SizedBox(height: 16),

          _buildQuestionField(
            isDark: isDark,
            icon: Icons.flag_outlined,
            question: 'Was sind deine Ziele für nächste Woche?',
            hint: 'Deine Vorhaben und Pläne...',
            controller: _weeklyGoalsController,
            color: NexusTheme.primaryColor,
          ),
          const SizedBox(height: 24),

          _buildSaveButton(_saveWeeklyReview),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildHistory(bool isDark) {
    final allReviews = <dynamic>[..._dailyReviews, ..._weeklyReviews];
    allReviews.sort((a, b) {
      final dateA = a is ReviewEntry ? a.date : (a as WeeklyReviewEntry).weekStart;
      final dateB = b is ReviewEntry ? b.date : (b as WeeklyReviewEntry).weekStart;
      return dateB.compareTo(dateA);
    });

    if (allReviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: isDark ? Colors.white24 : Colors.black26,
            ),
            const SizedBox(height: 16),
            Text(
              'Noch keine Reviews',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Schreibe dein erstes Review!',
              style: TextStyle(
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: allReviews.length,
      itemBuilder: (context, index) {
        final review = allReviews[index];
        if (review is ReviewEntry) {
          return _buildDailyReviewCard(review, isDark);
        } else {
          return _buildWeeklyReviewCard(review as WeeklyReviewEntry, isDark);
        }
      },
    );
  }

  Widget _buildDailyReviewCard(ReviewEntry review, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDailyReviewDetails(review),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: NexusTheme.primaryGradient,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.wb_sunny, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDate(review.date),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : NexusTheme.lightText,
                      ),
                    ),
                    Text(
                      'Tages-Review',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getEnergyColor(review.energy).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt, size: 16, color: _getEnergyColor(review.energy)),
                    const SizedBox(width: 4),
                    Text(
                      '${review.energy}/10',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _getEnergyColor(review.energy),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyReviewCard(WeeklyReviewEntry review, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showWeeklyReviewDetails(review),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [NexusTheme.secondaryColor, NexusTheme.accentColor],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.date_range, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'KW ${review.weekNumber}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : NexusTheme.lightText,
                      ),
                    ),
                    Text(
                      'Wochen-Review',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionField({
    required bool isDark,
    required IconData icon,
    required String question,
    required String hint,
    required TextEditingController controller,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(
              question,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : NexusTheme.lightText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDark ? Colors.white38 : Colors.black38,
            ),
            filled: true,
            fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: color),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnergySlider(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.bolt, size: 20, color: NexusTheme.warning),
            const SizedBox(width: 8),
            Text(
              'Energie-Level',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : NexusTheme.lightText,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _getEnergyColor(_dailyEnergy).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$_dailyEnergy/10',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _getEnergyColor(_dailyEnergy),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
            ),
          ),
          child: Column(
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: _getEnergyColor(_dailyEnergy),
                  inactiveTrackColor: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                  thumbColor: _getEnergyColor(_dailyEnergy),
                  overlayColor: _getEnergyColor(_dailyEnergy).withOpacity(0.2),
                  trackHeight: 8,
                ),
                child: Slider(
                  value: _dailyEnergy.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  onChanged: (value) => setState(() => _dailyEnergy = value.round()),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Erschöpft',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                  Text(
                    'Voller Energie',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(VoidCallback onSave) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: NexusTheme.primaryGradient,
          ),
          borderRadius: BorderRadius.circular(12),
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
            borderRadius: BorderRadius.circular(12),
            onTap: _isSaving ? null : onSave,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.save, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Speichern',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getEnergyColor(int energy) {
    if (energy <= 3) return NexusTheme.danger;
    if (energy <= 6) return NexusTheme.warning;
    return NexusTheme.success;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;

    if (diff == 0) return 'Heute';
    if (diff == 1) return 'Gestern';
    if (diff < 7) return 'Vor $diff Tagen';

    return DateFormat('d. MMMM yyyy', 'de_DE').format(date);
  }

  void _showDailyReviewDetails(ReviewEntry review) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black26,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: NexusTheme.primaryGradient),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.wb_sunny, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDate(review.date),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : NexusTheme.lightText,
                        ),
                      ),
                      Text(
                        'Tages-Review',
                        style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getEnergyColor(review.energy).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.bolt, size: 18, color: _getEnergyColor(review.energy)),
                      const SizedBox(width: 4),
                      Text(
                        '${review.energy}/10',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getEnergyColor(review.energy),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (review.achieved.isNotEmpty)
              _buildDetailSection('Was erreicht', review.achieved, Icons.check_circle_outline, NexusTheme.success, isDark),
            if (review.good.isNotEmpty)
              _buildDetailSection('Was gut lief', review.good, Icons.thumb_up_outlined, NexusTheme.info, isDark),
            if (review.better.isNotEmpty)
              _buildDetailSection('Was besser werden kann', review.better, Icons.trending_up, NexusTheme.warning, isDark),
            if (review.focus.isNotEmpty)
              _buildDetailSection('Fokus morgen', review.focus, Icons.track_changes, NexusTheme.primaryColor, isDark),
            if (review.grateful.isNotEmpty)
              _buildDetailSection('Dankbar für', review.grateful, Icons.favorite_outline, NexusTheme.danger, isDark),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                setState(() => _dailyReviews.remove(review));
              },
              icon: Icon(Icons.delete, color: NexusTheme.danger),
              label: Text('Löschen', style: TextStyle(color: NexusTheme.danger)),
            ),
          ],
        ),
      ),
    );
  }

  void _showWeeklyReviewDetails(WeeklyReviewEntry review) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black26,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [NexusTheme.secondaryColor, NexusTheme.accentColor]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.date_range, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'KW ${review.weekNumber}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : NexusTheme.lightText,
                        ),
                      ),
                      Text(
                        'Wochen-Review',
                        style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (review.highlights.isNotEmpty)
              _buildDetailSection('Highlights', review.highlights, Icons.star_outline, NexusTheme.warning, isDark),
            if (review.progress.isNotEmpty)
              _buildDetailSection('Fortschritt', review.progress, Icons.trending_up, NexusTheme.success, isDark),
            if (review.challenges.isNotEmpty)
              _buildDetailSection('Herausforderungen', review.challenges, Icons.warning_amber_outlined, NexusTheme.danger, isDark),
            if (review.learnings.isNotEmpty)
              _buildDetailSection('Learnings', review.learnings, Icons.lightbulb_outline, NexusTheme.info, isDark),
            if (review.goals.isNotEmpty)
              _buildDetailSection('Ziele nächste Woche', review.goals, Icons.flag_outlined, NexusTheme.primaryColor, isDark),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                setState(() => _weeklyReviews.remove(review));
              },
              icon: Icon(Icons.delete, color: NexusTheme.danger),
              label: Text('Löschen', style: TextStyle(color: NexusTheme.danger)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, String content, IconData icon, Color color, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              content,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ReviewEntry {
  final String id;
  final DateTime date;
  final String achieved;
  final String good;
  final String better;
  final String focus;
  final String grateful;
  final int energy;

  ReviewEntry({
    required this.id,
    required this.date,
    required this.achieved,
    required this.good,
    required this.better,
    required this.focus,
    required this.grateful,
    required this.energy,
  });
}

class WeeklyReviewEntry {
  final String id;
  final DateTime weekStart;
  final int weekNumber;
  final String highlights;
  final String progress;
  final String challenges;
  final String learnings;
  final String goals;

  WeeklyReviewEntry({
    required this.id,
    required this.weekStart,
    required this.weekNumber,
    required this.highlights,
    required this.progress,
    required this.challenges,
    required this.learnings,
    required this.goals,
  });
}
