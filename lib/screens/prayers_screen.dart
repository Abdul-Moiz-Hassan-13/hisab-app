import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ── Palette (mirrors HomeScreen) ──────────────────────────────────────────────
const _bgColor     = Color(0xFFFAF7F4);
const _primaryText = Color(0xFF2D2016);
const _subtleText  = Color(0xFF7A6A55);
const _accentGold  = Color(0xFFC4954A);
const _cardWhite   = Colors.white;
const _prayerColor = Color(0xFFB5835A);

// Arabic names for each prayer
const _arabicNames = {
  'Fajr':    'الفجر',
  'Zuhr':    'الظهر',
  'Asr':     'العصر',
  'Maghrib': 'المغرب',
  'Isha':    'العشاء',
  'Witr':    'الوتر',
};

class PrayersScreen extends StatefulWidget {
  const PrayersScreen({super.key, required this.initialCounts});
  final Map<String, int> initialCounts;

  @override
  State<PrayersScreen> createState() => _PrayersScreenState();
}

class _PrayersScreenState extends State<PrayersScreen>
    with SingleTickerProviderStateMixin {
  static const int _maxCount = 300000;

  late final List<String> _prayers;
  late final Map<String, int> _counts;
  late final Map<String, TextEditingController> _controllers;
  late final AnimationController _animController;
  late final List<Animation<double>> _fadeAnims;
  late final List<Animation<Offset>> _slideAnims;

  bool _isShowingLimitAlert = false;

  int get _grandTotal => _counts.values.fold(0, (s, v) => s + v);

  @override
  void initState() {
    super.initState();
    _prayers  = ['Fajr', 'Zuhr', 'Asr', 'Maghrib', 'Isha', 'Witr'];
    _counts   = Map<String, int>.from(widget.initialCounts);
    _controllers = {
      for (final p in _prayers)
        p: TextEditingController(text: (_counts[p] ?? 0).toString()),
    };

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnims = List.generate(_prayers.length + 2, (i) {
      final start = (i * 0.08).clamp(0.0, 0.7);
      final end   = (start + 0.4).clamp(0.0, 1.0);
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _animController,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });

    _slideAnims = List.generate(_prayers.length + 2, (i) {
      final start = (i * 0.08).clamp(0.0, 0.7);
      final end   = (start + 0.4).clamp(0.0, 1.0);
      return Tween<Offset>(
        begin: const Offset(0, 0.18),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _animController,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });

    _animController.forward();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) c.dispose();
    _animController.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _showLimitAlert() {
    if (_isShowingLimitAlert) return;
    _isShowingLimitAlert = true;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Limit Reached',
          style: TextStyle(
            color: _primaryText,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        content: const Text(
          'Maximum allowed count is 300,000.',
          style: TextStyle(color: _subtleText, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Got it',
              style: TextStyle(
                color: _prayerColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ).whenComplete(() => _isShowingLimitAlert = false);
  }

  void _increment(String prayer) {
    final count = _counts[prayer] ?? 0;
    if (count >= _maxCount) { _showLimitAlert(); return; }
    setState(() {
      _counts[prayer] = count + 1;
      _controllers[prayer]!.text = (count + 1).toString();
    });
  }

  void _decrement(String prayer) {
    final count = _counts[prayer] ?? 0;
    if (count <= 0) return;
    setState(() {
      _counts[prayer] = count - 1;
      _controllers[prayer]!.text = (count - 1).toString();
    });
  }

  void _onTextChanged(String prayer, String value) {
    final parsed = int.tryParse(value);
    if (parsed != null && parsed > _maxCount) {
      _showLimitAlert();
      setState(() {
        _counts[prayer] = _maxCount;
        final ctrl = _controllers[prayer]!;
        ctrl.text = _maxCount.toString();
        ctrl.selection = TextSelection.collapsed(offset: ctrl.text.length);
      });
      return;
    }
    setState(() => _counts[prayer] = parsed ?? 0);
  }

  void _onTextSubmitted(String prayer, String value) {
    final parsed = int.tryParse(value);
    if (parsed == null) {
      setState(() {
        _counts[prayer] = 0;
        _controllers[prayer]!.text = '0';
      });
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) Navigator.pop(context, _counts);
      },
      child: Scaffold(
        backgroundColor: _bgColor,
        body: Stack(
          children: [
            // Background blobs
            Positioned(
              top: -60, right: -60,
              child: _Blob(size: 220, color: _prayerColor.withValues(alpha: 0.06)),
            ),
            Positioned(
              bottom: -80, left: -80,
              child: _Blob(size: 280, color: _accentGold.withValues(alpha: 0.05)),
            ),

            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── App bar ──────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 12, 20, 0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 18,
                            color: _primaryText,
                          ),
                          onPressed: () => Navigator.pop(context, _counts),
                        ),
                        const Spacer(),
                        const Text(
                          'Missed Prayers',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: _primaryText,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(width: 40), // balance
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Summary card ─────────────────────────────────
                  FadeTransition(
                    opacity: _fadeAnims[0],
                    child: SlideTransition(
                      position: _slideAnims[0],
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _SummaryCard(total: _grandTotal),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Section label
                  FadeTransition(
                    opacity: _fadeAnims[1],
                    child: SlideTransition(
                      position: _slideAnims[1],
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'PRAYERS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFAA9480),
                            letterSpacing: 1.8,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ── Prayer list ──────────────────────────────────
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: _prayers.length,
                      itemBuilder: (context, index) {
                        final prayer = _prayers[index];
                        final count  = _counts[prayer] ?? 0;
                        final animIdx = index + 2;

                        return FadeTransition(
                          opacity: _fadeAnims[animIdx],
                          child: SlideTransition(
                            position: _slideAnims[animIdx],
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _PrayerCard(
                                prayer:     prayer,
                                arabicName: _arabicNames[prayer] ?? '',
                                count:      count,
                                controller: _controllers[prayer]!,
                                onIncrement: () => _increment(prayer),
                                onDecrement: () => _decrement(prayer),
                                onChanged:   (v) => _onTextChanged(prayer, v),
                                onSubmitted: (v) => _onTextSubmitted(prayer, v),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Summary card ──────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.total});
  final int total;

  @override
  Widget build(BuildContext context) {
    final isZero = total == 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _prayerColor.withValues(alpha: 0.13),
            _prayerColor.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _prayerColor.withValues(alpha: 0.20),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _prayerColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.self_improvement_rounded,
              color: _prayerColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isZero ? 'All prayers accounted for' : '$total prayers remaining',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _primaryText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isZero
                    ? 'Ma Sha Allah, nothing pending.'
                    : 'Across all prayer types below.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: _subtleText.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Individual prayer card ────────────────────────────────────────────────────

class _PrayerCard extends StatelessWidget {
  const _PrayerCard({
    required this.prayer,
    required this.arabicName,
    required this.count,
    required this.controller,
    required this.onIncrement,
    required this.onDecrement,
    required this.onChanged,
    required this.onSubmitted,
  });

  final String               prayer;
  final String               arabicName;
  final int                  count;
  final TextEditingController controller;
  final VoidCallback          onIncrement;
  final VoidCallback          onDecrement;
  final ValueChanged<String>  onChanged;
  final ValueChanged<String>  onSubmitted;

  @override
  Widget build(BuildContext context) {
    final isZero = count == 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _prayerColor.withValues(alpha: isZero ? 0.08 : 0.20),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: _prayerColor.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Prayer name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prayer,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: _primaryText,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  arabicName,
                  style: TextStyle(
                    fontSize: 13,
                    color: _accentGold.withValues(alpha: 0.7),
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),

          // Counter controls
          Row(
            children: [
              // Decrement
              _CounterButton(
                icon: Icons.remove_rounded,
                onTap: isZero ? null : onDecrement,
                color: _prayerColor,
              ),

              // Text field
              Container(
                width: 60,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                child: TextField(
                  controller: controller,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: isZero
                        ? _subtleText.withValues(alpha: 0.35)
                        : _prayerColor,
                    letterSpacing: -0.3,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    filled: true,
                    fillColor: _prayerColor.withValues(alpha: 0.06),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: onChanged,
                  onSubmitted: onSubmitted,
                ),
              ),

              // Increment
              _CounterButton(
                icon: Icons.add_rounded,
                onTap: onIncrement,
                color: _prayerColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Counter button ────────────────────────────────────────────────────────────

class _CounterButton extends StatefulWidget {
  const _CounterButton({
    required this.icon,
    required this.color,
    this.onTap,
  });

  final IconData     icon;
  final Color        color;
  final VoidCallback? onTap;

  @override
  State<_CounterButton> createState() => _CounterButtonState();
}

class _CounterButtonState extends State<_CounterButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onTap == null;

    return GestureDetector(
      onTapDown:   (_) { if (!disabled) setState(() => _pressed = true); },
      onTapUp:     (_) { setState(() => _pressed = false); widget.onTap?.call(); },
      onTapCancel: ()  { setState(() => _pressed = false); },
      child: AnimatedScale(
        scale: _pressed ? 0.88 : 1.0,
        duration: const Duration(milliseconds: 90),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: disabled
                ? _subtleText.withValues(alpha: 0.06)
                : _pressed
                    ? widget.color.withValues(alpha: 0.22)
                    : widget.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            widget.icon,
            size: 18,
            color: disabled
                ? _subtleText.withValues(alpha: 0.25)
                : widget.color,
          ),
        ),
      ),
    );
  }
}

// ── Shared blob ───────────────────────────────────────────────────────────────

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});
  final double size;
  final Color  color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}