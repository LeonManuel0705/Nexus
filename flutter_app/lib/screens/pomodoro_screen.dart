import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import '../services/focus_mode_service.dart';

class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> with TickerProviderStateMixin {
  static const int workDuration = 25 * 60;
  static const int shortBreakDuration = 5 * 60;
  static const int longBreakDuration = 15 * 60;

  int _currentDuration = workDuration;
  int _remainingSeconds = workDuration;
  Timer? _timer;
  bool _isRunning = false;
  int _sessionsCompleted = 0;
  PomodoroMode _currentMode = PomodoroMode.work;
  bool _focusModeEnabled = false;
  bool _hasPermission = false;

  final FocusModeService _focusModeService = FocusModeService();

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
    _checkFocusModePermission();
  }

  Future<void> _checkFocusModePermission() async {
    final hasPermission = await _focusModeService.hasPermission();
    if (mounted) {
      setState(() => _hasPermission = hasPermission);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();

    if (_focusModeEnabled) {
      _focusModeService.disableFocusMode();
    }
    super.dispose();
  }

  void _startTimer() async {
    setState(() => _isRunning = true);

    if (_currentMode == PomodoroMode.work) {
      final enabled = await _focusModeService.enableFocusMode();
      if (mounted) {
        setState(() => _focusModeEnabled = enabled);
      }
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _onTimerComplete();
      }
    });
  }

  void _pauseTimer() async {
    _timer?.cancel();
    setState(() => _isRunning = false);

    if (_focusModeEnabled) {
      await _focusModeService.disableFocusMode();
      if (mounted) {
        setState(() => _focusModeEnabled = false);
      }
    }
  }

  void _resetTimer() async {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _remainingSeconds = _currentDuration;
    });

    if (_focusModeEnabled) {
      await _focusModeService.disableFocusMode();
      if (mounted) {
        setState(() => _focusModeEnabled = false);
      }
    }
  }

  void _onTimerComplete() async {
    _timer?.cancel();
    HapticFeedback.heavyImpact();

    if (_focusModeEnabled) {
      await _focusModeService.disableFocusMode();
      if (mounted) {
        setState(() => _focusModeEnabled = false);
      }
    }

    setState(() {
      _isRunning = false;
      if (_currentMode == PomodoroMode.work) {
        _sessionsCompleted++;
        if (_sessionsCompleted % 4 == 0) {
          _switchMode(PomodoroMode.longBreak);
        } else {
          _switchMode(PomodoroMode.shortBreak);
        }
      } else {
        _switchMode(PomodoroMode.work);
      }
    });

    _showCompletionDialog();
  }

  void _switchMode(PomodoroMode mode) {
    setState(() {
      _currentMode = mode;
      switch (mode) {
        case PomodoroMode.work:
          _currentDuration = workDuration;
          break;
        case PomodoroMode.shortBreak:
          _currentDuration = shortBreakDuration;
          break;
        case PomodoroMode.longBreak:
          _currentDuration = longBreakDuration;
          break;
      }
      _remainingSeconds = _currentDuration;
    });
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_currentMode == PomodoroMode.work ? 'Pause beendet!' : 'Session beendet!'),
        content: Text(
          _currentMode == PomodoroMode.work
              ? 'Zeit zu arbeiten! Du hast $_sessionsCompleted Sessions abgeschlossen.'
              : 'Gut gemacht! Nimm dir eine ${_currentMode == PomodoroMode.longBreak ? 'lange' : 'kurze'} Pause.',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _startTimer();
            },
            child: const Text('Starten'),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  double get _progress => _remainingSeconds / _currentDuration;

  Color get _modeColor {
    switch (_currentMode) {
      case PomodoroMode.work:
        return NexusTheme.pomodoroColor;
      case PomodoroMode.shortBreak:
        return NexusTheme.success;
      case PomodoroMode.longBreak:
        return NexusTheme.info;
    }
  }

  String get _modeLabel {
    switch (_currentMode) {
      case PomodoroMode.work:
        return 'Fokus';
      case PomodoroMode.shortBreak:
        return 'Kurze Pause';
      case PomodoroMode.longBreak:
        return 'Lange Pause';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Pomodoro',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Fokussiere dich mit der Pomodoro-Technik',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 32),

        Center(
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isRunning ? _pulseAnimation.value : 1.0,
                child: child,
              );
            },
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? NexusTheme.darkCard : NexusTheme.lightCard,
                boxShadow: [
                  BoxShadow(
                    color: _modeColor.withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [

                  SizedBox(
                    width: 260,
                    height: 260,
                    child: CircularProgressIndicator(
                      value: _progress,
                      strokeWidth: 8,
                      backgroundColor: isDark
                          ? NexusTheme.darkBorder
                          : NexusTheme.lightBorder,
                      valueColor: AlwaysStoppedAnimation<Color>(_modeColor),
                      strokeCap: StrokeCap.round,
                    ),
                  ),

                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: _modeColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _modeLabel,
                          style: TextStyle(
                            color: _modeColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatTime(_remainingSeconds),
                        style: TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                          color: isDark ? NexusTheme.darkText : NexusTheme.lightText,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 32),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildControlButton(
              icon: Icons.refresh,
              onPressed: _resetTimer,
              color: isDark ? NexusTheme.darkTextMuted : NexusTheme.lightTextMuted,
            ),
            const SizedBox(width: 24),
            _buildMainButton(isDark),
            const SizedBox(width: 24),
            _buildControlButton(
              icon: Icons.skip_next,
              onPressed: () {
                _timer?.cancel();
                _onTimerComplete();
              },
              color: isDark ? NexusTheme.darkTextMuted : NexusTheme.lightTextMuted,
            ),
          ],
        ),

        const SizedBox(height: 32),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Modus wählen',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildModeChip(
                        label: 'Fokus',
                        mode: PomodoroMode.work,
                        duration: '25 min',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildModeChip(
                        label: 'Kurz',
                        mode: PomodoroMode.shortBreak,
                        duration: '5 min',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildModeChip(
                        label: 'Lang',
                        mode: PomodoroMode.longBreak,
                        duration: '15 min',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: NexusTheme.pomodoroColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.local_fire_department,
                    color: NexusTheme.pomodoroColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Heute abgeschlossen',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        '$_sessionsCompleted Sessions',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${_sessionsCompleted * 25} min',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: NexusTheme.pomodoroColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (_focusModeEnabled
                            ? NexusTheme.success
                            : NexusTheme.info)
                        .withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _focusModeEnabled
                        ? Icons.do_not_disturb_on
                        : Icons.do_not_disturb_off,
                    color:
                        _focusModeEnabled ? NexusTheme.success : NexusTheme.info,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fokus-Modus',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _focusModeEnabled
                            ? 'Benachrichtigungen blockiert'
                            : _hasPermission
                                ? 'Startet automatisch mit Timer'
                                : 'Berechtigung erforderlich',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (!_hasPermission)
                  TextButton(
                    onPressed: () async {
                      await _focusModeService.requestPermission();
                      await _checkFocusModePermission();
                    },
                    child: const Text('Erlauben'),
                  )
                else if (_focusModeEnabled)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: NexusTheme.success.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Aktiv',
                      style: TextStyle(
                        color: NexusTheme.success,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildMainButton(bool isDark) {
    return GestureDetector(
      onTap: _isRunning ? _pauseTimer : _startTimer,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [_modeColor, _modeColor.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: _modeColor.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(
          _isRunning ? Icons.pause : Icons.play_arrow,
          color: Colors.white,
          size: 36,
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 28),
      color: color,
      style: IconButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        padding: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildModeChip({
    required String label,
    required PomodoroMode mode,
    required String duration,
  }) {
    final isSelected = _currentMode == mode;
    final color = mode == PomodoroMode.work
        ? NexusTheme.pomodoroColor
        : mode == PomodoroMode.shortBreak
            ? NexusTheme.success
            : NexusTheme.info;

    return GestureDetector(
      onTap: () {
        if (!_isRunning) {
          _switchMode(mode);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : null,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            Text(
              duration,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isSelected ? color : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum PomodoroMode { work, shortBreak, longBreak }
