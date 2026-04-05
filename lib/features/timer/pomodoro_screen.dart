import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

enum PomodoroPhase { focus, shortBreak, longBreak }

class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});
  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> with TickerProviderStateMixin {
  static const _focusMins      = 25;
  static const _shortBreakMins = 5;
  static const _longBreakMins  = 15;

  PomodoroPhase _phase = PomodoroPhase.focus;
  int _secondsLeft = _focusMins * 60;
  bool _isRunning  = false;
  int _sessions    = 0;
  Timer? _timer;

  late AnimationController _pulseCtrl;
  late Animation<double>   _pulse;
  late AnimationController _rotateCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _rotateCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 8))
      ..repeat();
  }

  @override
  void dispose() { _timer?.cancel(); _pulseCtrl.dispose(); _rotateCtrl.dispose(); super.dispose(); }

  int get _total {
    switch (_phase) {
      case PomodoroPhase.focus:      return _focusMins * 60;
      case PomodoroPhase.shortBreak: return _shortBreakMins * 60;
      case PomodoroPhase.longBreak:  return _longBreakMins * 60;
    }
  }

  double get _progress => 1 - (_secondsLeft / _total);

  String get _timeLabel {
    final m = _secondsLeft ~/ 60, s = _secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  LinearGradient get _gradient {
    switch (_phase) {
      case PomodoroPhase.focus:      return AppTheme.primaryGradient;
      case PomodoroPhase.shortBreak: return AppTheme.successGradient;
      case PomodoroPhase.longBreak:  return AppTheme.tealGradient;
    }
  }

  Color get _primaryColor => _gradient.colors.first;

  String get _phaseLabel {
    switch (_phase) {
      case PomodoroPhase.focus:      return '🎯 Focus Time';
      case PomodoroPhase.shortBreak: return '☕ Short Break';
      case PomodoroPhase.longBreak:  return '🌿 Long Break';
    }
  }

  void _startStop() {
    if (_isRunning) {
      _timer?.cancel();
      _pulseCtrl.stop();
      setState(() => _isRunning = false);
    } else {
      _pulseCtrl.repeat(reverse: true);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_secondsLeft <= 0) _onComplete();
        else setState(() => _secondsLeft--);
      });
      setState(() => _isRunning = true);
    }
  }

  void _onComplete() {
    _timer?.cancel(); _pulseCtrl.stop();
    setState(() {
      _isRunning = false;
      if (_phase == PomodoroPhase.focus) {
        _sessions++;
        _phase = _sessions % 4 == 0 ? PomodoroPhase.longBreak : PomodoroPhase.shortBreak;
      } else {
        _phase = PomodoroPhase.focus;
      }
      _secondsLeft = _total;
    });
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(_phase == PomodoroPhase.focus ? '🎯 Back to focus!' : '☕ Take a break!',
        style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
      backgroundColor: _primaryColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _reset() {
    _timer?.cancel(); _pulseCtrl.stop();
    setState(() { _isRunning = false; _secondsLeft = _total; });
  }

  void _setPhase(PomodoroPhase p) {
    _timer?.cancel(); _pulseCtrl.stop();
    setState(() { _isRunning = false; _phase = p; _secondsLeft = _total; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: _gradient),
        child: SafeArea(
          child: Column(children: [
            _buildAppBar(),
            _buildPhaseChips(),
            const Spacer(),
            _buildTimerRing(),
            const Spacer(),
            _buildSessionCount(),
            const SizedBox(height: 32),
            _buildControls(),
            const SizedBox(height: 48),
          ]),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        Expanded(child: Text('Pomodoro Timer',
          style: GoogleFonts.nunito(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800))),
      ]),
    );
  }

  Widget _buildPhaseChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _phaseChip('Focus', PomodoroPhase.focus, _focusMins),
          const SizedBox(width: 8),
          _phaseChip('Short Break', PomodoroPhase.shortBreak, _shortBreakMins),
          const SizedBox(width: 8),
          _phaseChip('Long Break', PomodoroPhase.longBreak, _longBreakMins),
        ],
      ),
    );
  }

  Widget _phaseChip(String label, PomodoroPhase phase, int mins) {
    final selected = _phase == phase;
    return GestureDetector(
      onTap: () => _setPhase(phase),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(children: [
          Text(label, style: GoogleFonts.nunito(
            color: selected ? _primaryColor : Colors.white,
            fontSize: 12, fontWeight: FontWeight.w700)),
          Text('${mins}m', style: GoogleFonts.nunito(
            color: selected ? _primaryColor.withValues(alpha: 0.7) : Colors.white60,
            fontSize: 10)),
        ]),
      ),
    );
  }

  Widget _buildTimerRing() {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => Transform.scale(
        scale: _isRunning ? _pulse.value : 1.0,
        child: SizedBox(
          width: 260, height: 260,
          child: Stack(alignment: Alignment.center, children: [
            // Outer glow ring
            Container(
              width: 260, height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            // Progress ring
            SizedBox(
              width: 220, height: 220,
              child: CircularProgressIndicator(
                value: _progress,
                strokeWidth: 14,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                strokeCap: StrokeCap.round,
              ),
            ),
            // Center content
            Column(mainAxisSize: MainAxisSize.min, children: [
              Text(_timeLabel, style: GoogleFonts.nunito(
                color: Colors.white, fontSize: 60, fontWeight: FontWeight.w800)),
              Text(_phaseLabel, style: GoogleFonts.nunito(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 14, fontWeight: FontWeight.w600)),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _buildSessionCount() {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      ...List.generate(4, (i) => Container(
        width: i < _sessions % 4 || (_sessions > 0 && _sessions % 4 == 0) ? 32 : 10,
        height: 10,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: i < (_sessions % 4 == 0 && _sessions > 0 ? 4 : _sessions % 4)
              ? Colors.white
              : Colors.white.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(5),
        ),
      )),
      const SizedBox(width: 10),
      Text('$_sessions session${_sessions != 1 ? 's' : ''}',
        style: GoogleFonts.nunito(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
    ]);
  }

  Widget _buildControls() {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      _controlBtn(Icons.restart_alt_rounded, Colors.white.withValues(alpha: 0.25), _reset, 52),
      const SizedBox(width: 24),
      GestureDetector(
        onTap: _startStop,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: Icon(_isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
            color: _primaryColor, size: 40),
        ),
      ),
      const SizedBox(width: 24),
      _controlBtn(Icons.skip_next_rounded, Colors.white.withValues(alpha: 0.25), _onComplete, 52),
    ]);
  }

  Widget _controlBtn(IconData icon, Color bg, VoidCallback onTap, double size) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: size * 0.45),
      ),
    );
  }
}
