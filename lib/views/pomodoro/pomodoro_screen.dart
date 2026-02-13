import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/timer_mode.dart';
import '../../view_models/timer_view_model.dart';
import '../../widgets/painters/ring_painter.dart';
import '../../widgets/painters/tick_painter.dart';

class PomodoroScreen extends StatefulWidget {
  final TimerViewModel viewModel;

  const PomodoroScreen({super.key, required this.viewModel});

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _pulseController;
  late AnimationController _breatheController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _breatheAnimation;

  TimerViewModel get _vm => widget.viewModel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _vm.addListener(_onViewModelChanged);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
    _breatheAnimation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _breatheController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _vm.removeListener(_onViewModelChanged);
    _pulseController.dispose();
    _breatheController.dispose();
    super.dispose();
  }

  void _onViewModelChanged() => setState(() {});

  // ─── Lifecycle ──────────────────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _vm.onAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      _vm.onAppResumed();
    }
  }

  // ─── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final ringSize = screenSize.width * 0.72;

    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 24),
          _buildModeSelector(),
          const Spacer(flex: 2),
          _buildTimerRing(ringSize),
          const Spacer(flex: 1),
          _buildPomodoroCount(),
          const Spacer(flex: 1),
          _buildControls(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ─── Mode Selector ────────────────────────────────────────────────────

  Widget _buildModeSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _modeTab('Focus', TimerMode.focus),
          _modeTab('Short', TimerMode.shortBreak),
          _modeTab('Long', TimerMode.longBreak),
        ],
      ),
    );
  }

  Widget _modeTab(String label, TimerMode mode) {
    final isActive = _vm.mode == mode;
    final color =
        mode == TimerMode.focus ? AppColors.accent : AppColors.breakAccent;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (!_vm.isRunning) _vm.switchMode(mode);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? color.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive ? color : AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  // ─── Timer Ring ──────────────────────────────────────────────────────────

  Widget _buildTimerRing(double size) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _breatheAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_vm.isRunning)
                  Container(
                    width: size + 20,
                    height: size + 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _vm.activeGlow.withOpacity(
                            _breatheAnimation.value * 0.3,
                          ),
                          blurRadius: 60,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  ),
                CustomPaint(
                  size: Size(size, size),
                  painter: RingPainter(
                    progress: 1.0,
                    color: AppColors.surfaceLight,
                    strokeWidth: 6,
                  ),
                ),
                CustomPaint(
                  size: Size(size, size),
                  painter: RingPainter(
                    progress: _vm.progress,
                    color: _vm.activeColor,
                    strokeWidth: 6,
                    hasGlow: true,
                    glowColor: _vm.activeGlow,
                  ),
                ),
                CustomPaint(
                  size: Size(size, size),
                  painter: TickPainter(
                    activeColor: _vm.activeColor,
                    progress: _vm.progress,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _vm.modeLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _vm.activeColor.withOpacity(0.7),
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _vm.timeDisplay,
                      style: TextStyle(
                        fontSize: size * 0.2,
                        fontWeight: FontWeight.w200,
                        color: AppColors.textPrimary,
                        letterSpacing: 4,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(_vm.state.totalSeconds ~/ 60)} min session',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Pomodoro Count ──────────────────────────────────────────────────────

  Widget _buildPomodoroCount() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) {
        final filled = i < (_vm.completedPomodoros % 4);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: filled ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: filled ? AppColors.accent : AppColors.surfaceLight,
            boxShadow: [
              BoxShadow(
                color: filled ? AppColors.accentGlow : Colors.transparent,
                blurRadius: filled ? 8 : 0,
              ),
            ],
          ),
        );
      }),
    );
  }

  // ─── Controls ────────────────────────────────────────────────────────────

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _iconButton(
            icon: Icons.refresh_rounded,
            onTap: () {
              _pulseController
                  .forward()
                  .then((_) => _pulseController.reverse());
              _vm.reset();
            },
          ),
          const SizedBox(width: 24),
          GestureDetector(
            onTap: () {
              _pulseController
                  .forward()
                  .then((_) => _pulseController.reverse());
              _vm.toggleTimer();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _vm.activeColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _vm.activeGlow,
                    blurRadius: _vm.isRunning ? 24 : 16,
                    spreadRadius: _vm.isRunning ? 4 : 0,
                  ),
                ],
              ),
              child: Icon(
                _vm.isRunning
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
          const SizedBox(width: 24),
          _iconButton(
            icon: Icons.skip_next_rounded,
            onTap: _vm.skipToNext,
          ),
        ],
      ),
    );
  }

  Widget _iconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.surfaceLight, width: 1),
        ),
        child: Icon(icon, color: AppColors.textSecondary, size: 22),
      ),
    );
  }
}
