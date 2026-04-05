import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

enum PomodoroPhase { focus, shortBreak, longBreak }

class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen>
    with TickerProviderStateMixin {
  static const _focusMinutes = 25;
  static const _shortBreakMinutes = 5;
  static const _longBreakMinutes = 15;

  PomodoroPhase _phase = PomodoroPhase.focus;
  int _secondsLeft = _focusMinutes * 60;
  bool _isRunning = false;
  int _completedSessions = 0;
  Timer? _timer;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  int get _totalSeconds {
    switch (_phase) {
      case PomodoroPhase.focus:
        return _focusMinutes * 60;
      case PomodoroPhase.shortBreak:
        return _shortBreakMinutes * 60;
      case PomodoroPhase.longBreak:
        return _longBreakMinutes * 60;
    }
  }

  double get _progress => 1 - (_secondsLeft / _totalSeconds);

  String get _timeLabel {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Color get _phaseColor {
    switch (_phase) {
      case PomodoroPhase.focus:
        return AppTheme.primary;
      case PomodoroPhase.shortBreak:
        return AppTheme.success;
      case PomodoroPhase.longBreak:
        return AppTheme.teal;
    }
  }

  String get _phaseLabel {
    switch (_phase) {
      case PomodoroPhase.focus:
        return 'Focus Time';
      case PomodoroPhase.shortBreak:
        return 'Short Break';
      case PomodoroPhase.longBreak:
        return 'Long Break';
    }
  }

  void _startStop() {
    if (_isRunning) {
      _timer?.cancel();
      _pulseController.stop();
      setState(() => _isRunning = false);
    } else {
      _pulseController.repeat(reverse: true);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_secondsLeft <= 0) {
          _onPhaseComplete();
        } else {
          setState(() => _secondsLeft--);
        }
      });
      setState(() => _isRunning = true);
    }
  }

  void _onPhaseComplete() {
    _timer?.cancel();
    _pulseController.stop();
    setState(() {
      _isRunning = false;
      if (_phase == PomodoroPhase.focus) {
        _completedSessions++;
        _phase = _completedSessions % 4 == 0
            ? PomodoroPhase.longBreak
            : PomodoroPhase.shortBreak;
      } else {
        _phase = PomodoroPhase.focus;
      }
      _secondsLeft = _totalSeconds;
    });
    _showPhaseCompleteSnack();
  }

  void _showPhaseCompleteSnack() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _phase == PomodoroPhase.focus ? 'Break time!' : 'Back to focus!',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _phaseColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _reset() {
    _timer?.cancel();
    _pulseController.stop();
    setState(() {
      _isRunning = false;
      _secondsLeft = _totalSeconds;
    });
  }

  void _setPhase(PomodoroPhase phase) {
    _timer?.cancel();
    _pulseController.stop();
    setState(() {
      _isRunning = false;
      _phase = phase;
      _secondsLeft = _totalSeconds;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _phaseColor.withValues(alpha: 0.05),
      appBar: AppBar(
        title: const Text('Pomodoro Timer'),
        backgroundColor: _phaseColor,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Phase selector chips
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildPhaseChip('Focus', PomodoroPhase.focus, _focusMinutes),
                  const SizedBox(width: 8),
                  _buildPhaseChip(
                    'Short Break',
                    PomodoroPhase.shortBreak,
                    _shortBreakMinutes,
                  ),
                  const SizedBox(width: 8),
                  _buildPhaseChip(
                    'Long Break',
                    PomodoroPhase.longBreak,
                    _longBreakMinutes,
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Timer ring
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (_, __) => Transform.scale(
                scale: _isRunning ? _pulseAnimation.value : 1.0,
                child: SizedBox(
                  width: 240,
                  height: 240,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 240,
                        height: 240,
                        child: CircularProgressIndicator(
                          value: _progress,
                          strokeWidth: 12,
                          backgroundColor: _phaseColor.withValues(alpha: 0.15),
                          valueColor: AlwaysStoppedAnimation<Color>(_phaseColor),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _timeLabel,
                            style: TextStyle(
                              fontSize: 56,
                              fontWeight: FontWeight.bold,
                              color: _phaseColor,
                              fontFamily: 'monospace',
                            ),
                          ),
                          Text(
                            _phaseLabel,
                            style: TextStyle(
                              color: _phaseColor.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const Spacer(),

            // Session counter
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.local_fire_department,
                  color: AppTheme.secondary,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  '$_completedSessions session${_completedSessions != 1 ? 's' : ''} completed',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Control buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Reset button
                IconButton(
                  onPressed: _reset,
                  icon: const Icon(Icons.restart_alt),
                  iconSize: 32,
                  color: Colors.grey.shade500,
                  tooltip: 'Reset',
                ),
                const SizedBox(width: 24),

                // Main play/pause button
                GestureDetector(
                  onTap: _startStop,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _phaseColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _phaseColor.withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isRunning ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),

                const SizedBox(width: 24),

                // Skip button
                IconButton(
                  onPressed: _onPhaseComplete,
                  icon: const Icon(Icons.skip_next),
                  iconSize: 32,
                  color: Colors.grey.shade500,
                  tooltip: 'Skip phase',
                ),
              ],
            ),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildPhaseChip(
    String label,
    PomodoroPhase phase,
    int minutes,
  ) {
    final isSelected = _phase == phase;
    final color = _phaseColor;
    return GestureDetector(
      onTap: () => _setPhase(phase),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade600,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${minutes}m',
              style: TextStyle(
                color: isSelected ? Colors.white70 : Colors.grey.shade400,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
