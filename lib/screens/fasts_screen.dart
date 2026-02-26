import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _bgColor    = Color(0xFFFAF7F4);
const _primaryText = Color(0xFF2D2016);
const _subtleText  = Color(0xFF7A6A55);
const _accentGold  = Color(0xFFC4954A);
const _cardWhite   = Colors.white;
const _fastColor   = Color(0xFF7A9E7E); // green — matches HomeScreen card

class FastsScreen extends StatefulWidget {
  const FastsScreen({
    super.key,
    required this.initialCount,
    this.initialOptionalCount = 0,
  });

  final int initialCount;
  final int initialOptionalCount;

  @override
  State<FastsScreen> createState() => _FastsScreenState();
}

class _FastsScreenState extends State<FastsScreen>
    with SingleTickerProviderStateMixin {
  static const int _maxCount = 300000;

  late int _compulsoryCount;
  late int _optionalCount;
  late final TextEditingController _compulsoryCtrl;
  late final TextEditingController _optionalCtrl;

  late final AnimationController _animController;
  late final List<Animation<double>> _fadeAnims;
  late final List<Animation<Offset>> _slideAnims;

  bool _isShowingLimitAlert = false;

  int get _totalCount => _compulsoryCount + _optionalCount;

  @override
  void initState() {
    super.initState();
    _compulsoryCount = widget.initialCount;
    _optionalCount   = widget.initialOptionalCount;
    _compulsoryCtrl  = TextEditingController(text: _compulsoryCount.toString());
    _optionalCtrl    = TextEditingController(text: _optionalCount.toString());

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnims = List.generate(6, (i) {
      final start = (i * 0.10).clamp(0.0, 0.70);
      final end   = (start + 0.40).clamp(0.0, 1.0);
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _animController,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });

    _slideAnims = List.generate(6, (i) {
      final start = (i * 0.10).clamp(0.0, 0.70);
      final end   = (start + 0.40).clamp(0.0, 1.0);
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
    _compulsoryCtrl.dispose();
    _optionalCtrl.dispose();
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
            child: const Text(
              'Got it',
              style: TextStyle(color: _fastColor, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    ).whenComplete(() => _isShowingLimitAlert = false);
  }

  void _change(
    bool isCompulsory,
    int delta, {
    String? rawValue,
  }) {
    final current = isCompulsory ? _compulsoryCount : _optionalCount;
    final ctrl    = isCompulsory ? _compulsoryCtrl  : _optionalCtrl;

    int next;
    if (rawValue != null) {
      final parsed = int.tryParse(rawValue);
      if (parsed != null && parsed > _maxCount) {
        _showLimitAlert();
        setState(() {
          if (isCompulsory) _compulsoryCount = _maxCount;
          else              _optionalCount   = _maxCount;
          ctrl.text = _maxCount.toString();
          ctrl.selection = TextSelection.collapsed(offset: ctrl.text.length);
        });
        return;
      }
      next = parsed ?? 0;
    } else {
      next = current + delta;
      if (next > _maxCount) { _showLimitAlert(); return; }
      if (next < 0) return;
    }

    setState(() {
      if (isCompulsory) _compulsoryCount = next;
      else              _optionalCount   = next;
      ctrl.text = next.toString();
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) Navigator.pop(context, _compulsoryCount);
      },
      child: Scaffold(
        backgroundColor: _bgColor,
        body: Stack(
          children: [
            // Background blobs
            Positioned(
              top: -60, right: -60,
              child: _Blob(size: 220, color: _fastColor.withValues(alpha: 0.06)),
            ),
            Positioned(
              bottom: -80, left: -80,
              child: _Blob(size: 280, color: _accentGold.withValues(alpha: 0.05)),
            ),

            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── App bar ────────────────────────────────────
                    _AnimatedEntry(
                      fade: _fadeAnims[0],
                      slide: _slideAnims[0],
                      child: Row(
                        children: [
                          _BackBtn(onTap: () => Navigator.pop(context, _compulsoryCount)),
                          const Spacer(),
                          const Text(
                            'Missed Fasts',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: _primaryText,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const Spacer(),
                          const SizedBox(width: 40),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Summary card ───────────────────────────────
                    _AnimatedEntry(
                      fade: _fadeAnims[1],
                      slide: _slideAnims[1],
                      child: _SummaryCard(
                        compulsory: _compulsoryCount,
                        optional: _optionalCount,
                        total: _totalCount,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Compulsory section ─────────────────────────
                    _AnimatedEntry(
                      fade: _fadeAnims[2],
                      slide: _slideAnims[2],
                      child: _SectionLabel(
                        label: 'COMPULSORY FASTS',
                        tooltip: 'Fasts that are obligatory to make up (Qada)',
                      ),
                    ),

                    const SizedBox(height: 10),

                    _AnimatedEntry(
                      fade: _fadeAnims[3],
                      slide: _slideAnims[3],
                      child: _FastCard(
                        title: 'Missed Fasts (Qada)',
                        subtitle: 'Obligatory fasts to make up',
                        arabicLabel: 'قَضَاء',
                        count: _compulsoryCount,
                        controller: _compulsoryCtrl,
                        color: _fastColor,
                        onIncrement: () => _change(true, 1),
                        onDecrement: () => _change(true, -1),
                        onChanged:   (v) => _change(true, 0, rawValue: v),
                        onSubmitted: (v) {
                          if (int.tryParse(v) == null) {
                            setState(() {
                              _compulsoryCount = 0;
                              _compulsoryCtrl.text = '0';
                            });
                          }
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Optional section ───────────────────────────
                    _AnimatedEntry(
                      fade: _fadeAnims[4],
                      slide: _slideAnims[4],
                      child: _SectionLabel(
                        label: 'OPTIONAL FASTS',
                        tooltip: 'Voluntary / Nafl fasts you want to track',
                      ),
                    ),

                    const SizedBox(height: 10),

                    _AnimatedEntry(
                      fade: _fadeAnims[5],
                      slide: _slideAnims[5],
                      child: _FastCard(
                        title: 'Voluntary Fasts (Nafl)',
                        subtitle: 'Sunnah, Ayyam al-Bid, Ashura…',
                        arabicLabel: 'نَافِلَة',
                        count: _optionalCount,
                        controller: _optionalCtrl,
                        color: const Color(0xFF6B8CAE), // blue tint
                        onIncrement: () => _change(false, 1),
                        onDecrement: () => _change(false, -1),
                        onChanged:   (v) => _change(false, 0, rawValue: v),
                        onSubmitted: (v) {
                          if (int.tryParse(v) == null) {
                            setState(() {
                              _optionalCount = 0;
                              _optionalCtrl.text = '0';
                            });
                          }
                        },
                      ),
                    ),

                    // Optional fasts examples chips
                    const SizedBox(height: 12),
                    _AnimatedEntry(
                      fade: _fadeAnims[5],
                      slide: _slideAnims[5],
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: const [
                          _InfoChip(label: 'Mondays & Thursdays'),
                          _InfoChip(label: 'Ayyam al-Bid'),
                          _InfoChip(label: 'Day of Ashura'),
                          _InfoChip(label: 'Day of Arafah'),
                          _InfoChip(label: 'Shawwal (6 days)'),
                        ],
                      ),
                    ),
                  ],
                ),
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
  const _SummaryCard({
    required this.compulsory,
    required this.optional,
    required this.total,
  });

  final int compulsory, optional, total;

  @override
  Widget build(BuildContext context) {
    final allClear = compulsory == 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _fastColor.withValues(alpha: 0.13),
            _fastColor.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _fastColor.withValues(alpha: 0.20),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _fastColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              allClear
                  ? Icons.check_circle_outline_rounded
                  : Icons.no_meals_rounded,
              color: _fastColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  allClear
                      ? 'All fasts accounted for'
                      : '$compulsory compulsory fast${compulsory == 1 ? '' : 's'} remaining',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _primaryText,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  allClear
                      ? optional > 0
                          ? '$optional voluntary fast${optional == 1 ? '' : 's'} tracked.'
                          : 'MashaAllah — nothing pending.'
                      : optional > 0
                          ? 'Plus $optional voluntary fast${optional == 1 ? '' : 's'} tracked.'
                          : 'Update counts below.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: _subtleText.withValues(alpha: 0.75),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Fast counter card ─────────────────────────────────────────────────────────

class _FastCard extends StatelessWidget {
  const _FastCard({
    required this.title,
    required this.subtitle,
    required this.arabicLabel,
    required this.count,
    required this.controller,
    required this.color,
    required this.onIncrement,
    required this.onDecrement,
    required this.onChanged,
    required this.onSubmitted,
  });

  final String               title;
  final String               subtitle;
  final String               arabicLabel;
  final int                  count;
  final TextEditingController controller;
  final Color                color;
  final VoidCallback          onIncrement;
  final VoidCallback          onDecrement;
  final ValueChanged<String>  onChanged;
  final ValueChanged<String>  onSubmitted;

  @override
  Widget build(BuildContext context) {
    final isZero = count == 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: isZero ? 0.08 : 0.22),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _primaryText,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: _subtleText.withValues(alpha: 0.7),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                arabicLabel,
                style: TextStyle(
                  fontSize: 18,
                  color: _accentGold.withValues(alpha: 0.65),
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Counter row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Big count display
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$count',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        color: isZero
                            ? _subtleText.withValues(alpha: 0.25)
                            : color,
                        height: 1.0,
                        letterSpacing: -1.5,
                      ),
                    ),
                    TextSpan(
                      text: '  fasts',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _subtleText.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
              ),

              // Controls
              Row(
                children: [
                  _CounterButton(
                    icon: Icons.remove_rounded,
                    color: color,
                    onTap: isZero ? null : onDecrement,
                  ),
                  Container(
                    width: 62,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    child: TextField(
                      controller: controller,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isZero
                            ? _subtleText.withValues(alpha: 0.35)
                            : color,
                        letterSpacing: -0.3,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 9),
                        filled: true,
                        fillColor: color.withValues(alpha: 0.07),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: onChanged,
                      onSubmitted: onSubmitted,
                    ),
                  ),
                  _CounterButton(
                    icon: Icons.add_rounded,
                    color: color,
                    onTap: onIncrement,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Info chip ─────────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF6B8CAE).withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF6B8CAE).withValues(alpha: 0.18),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
          color: Color(0xFF4A6A8A),
        ),
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.tooltip});
  final String label;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: _subtleText.withValues(alpha: 0.55),
            letterSpacing: 1.8,
          ),
        ),
        const SizedBox(width: 6),
        Tooltip(
          message: tooltip,
          child: Icon(
            Icons.info_outline_rounded,
            size: 13,
            color: _subtleText.withValues(alpha: 0.35),
          ),
        ),
      ],
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
  final IconData      icon;
  final Color         color;
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
      onTapCancel: ()  => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.88 : 1.0,
        duration: const Duration(milliseconds: 90),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: disabled
                ? _subtleText.withValues(alpha: 0.06)
                : _pressed
                    ? widget.color.withValues(alpha: 0.22)
                    : widget.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(
            widget.icon,
            size: 19,
            color: disabled
                ? _subtleText.withValues(alpha: 0.25)
                : widget.color,
          ),
        ),
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

class _AnimatedEntry extends StatelessWidget {
  const _AnimatedEntry({
    required this.fade,
    required this.slide,
    required this.child,
  });
  final Animation<double> fade;
  final Animation<Offset> slide;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(position: slide, child: child),
    );
  }
}

class _BackBtn extends StatelessWidget {
  const _BackBtn({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _primaryText.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 16,
          color: _primaryText,
        ),
      ),
    );
  }
}

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