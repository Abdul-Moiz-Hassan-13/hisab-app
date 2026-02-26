import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _bgColor        = Color(0xFFFAF7F4);
const _primaryText    = Color(0xFF2D2016);
const _subtleText     = Color(0xFF7A6A55);
const _accentGold     = Color(0xFFC4954A);
const _cardWhite      = Colors.white;
const _expiationColor = Color(0xFF6B8CAE); // blue — matches HomeScreen card

// Expiation types with their Islamic context
const _expiationTypes = [
  _ExpiationType(
    key: 'oath',
    title: 'Broken Oath',
    arabicTitle: 'كَفَّارَةُ الْيَمِين',
    subtitle: 'Kaffarah for breaking a sworn oath',
    icon: Icons.handshake_outlined,
    remedies: [
      'Feed 10 poor people',
      'Clothe 10 poor people',
      'Free a slave (if applicable)',
      'Fast 3 days if unable',
    ],
  ),
  _ExpiationType(
    key: 'fast',
    title: 'Deliberately Broken Fast',
    arabicTitle: 'كَفَّارَةُ الصَّوْم',
    subtitle: 'Kaffarah for intentionally breaking Ramadan fast',
    icon: Icons.no_meals_rounded,
    remedies: [
      'Free a slave (if applicable)',
      'Fast 60 consecutive days',
      'Feed 60 poor people',
    ],
  ),
  _ExpiationType(
    key: 'zihar',
    title: 'Zihar',
    arabicTitle: 'كَفَّارَةُ الظِّهَار',
    subtitle: 'Kaffarah for Zihar (a form of unlawful oath)',
    icon: Icons.family_restroom_rounded,
    remedies: [
      'Free a slave (if applicable)',
      'Fast 2 consecutive months',
      'Feed 60 poor people',
    ],
  ),
  _ExpiationType(
    key: 'manslaughter',
    title: 'Unintentional Killing',
    arabicTitle: 'كَفَّارَةُ الْقَتْل',
    subtitle: 'Kaffarah for accidental manslaughter',
    icon: Icons.warning_amber_rounded,
    remedies: [
      'Free a slave (if applicable)',
      'Fast 2 consecutive months',
    ],
  ),
  _ExpiationType(
    key: 'other',
    title: 'Other Expiations',
    arabicTitle: 'كَفَّارَات أُخْرَى',
    subtitle: 'Any other obligatory kaffarah',
    icon: Icons.volunteer_activism_rounded,
    remedies: [
      'Consult a scholar for guidance',
    ],
  ),
];

// ── Data model ────────────────────────────────────────────────────────────────

class _ExpiationType {
  const _ExpiationType({
    required this.key,
    required this.title,
    required this.arabicTitle,
    required this.subtitle,
    required this.icon,
    required this.remedies,
  });

  final String       key;
  final String       title;
  final String       arabicTitle;
  final String       subtitle;
  final IconData     icon;
  final List<String> remedies;
}

// ── Screen ────────────────────────────────────────────────────────────────────

class ExpiationsScreen extends StatefulWidget {
  const ExpiationsScreen({super.key, required this.initialCount});
  final int initialCount;

  @override
  State<ExpiationsScreen> createState() => _ExpiationsScreenState();
}

class _ExpiationsScreenState extends State<ExpiationsScreen>
    with SingleTickerProviderStateMixin {
  static const int _maxCount = 300000;

  // One count per expiation type
  late final Map<String, int>                  _counts;
  late final Map<String, TextEditingController> _controllers;

  late final AnimationController       _animController;
  late final List<Animation<double>>   _fadeAnims;
  late final List<Animation<Offset>>   _slideAnims;

  bool _isShowingLimitAlert = false;

  int get _grandTotal => _counts.values.fold(0, (s, v) => s + v);

  @override
  void initState() {
    super.initState();

    // Distribute initialCount into the "other" bucket for backwards compat
    _counts = {
      for (final t in _expiationTypes) t.key: 0,
    };
    _counts['other'] = widget.initialCount;

    _controllers = {
      for (final t in _expiationTypes)
        t.key: TextEditingController(text: (_counts[t.key]!).toString()),
    };

    final itemCount = _expiationTypes.length + 3; // header + summary + cards
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnims = List.generate(itemCount, (i) {
      final start = (i * 0.08).clamp(0.0, 0.72);
      final end   = (start + 0.38).clamp(0.0, 1.0);
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _animController,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });

    _slideAnims = List.generate(itemCount, (i) {
      final start = (i * 0.08).clamp(0.0, 0.72);
      final end   = (start + 0.38).clamp(0.0, 1.0);
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
          style: TextStyle(color: _primaryText, fontWeight: FontWeight.w700, fontSize: 17),
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
              style: TextStyle(color: _expiationColor, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    ).whenComplete(() => _isShowingLimitAlert = false);
  }

  void _change(String key, int delta, {String? rawValue}) {
    final current = _counts[key]!;
    final ctrl    = _controllers[key]!;
    int next;

    if (rawValue != null) {
      final parsed = int.tryParse(rawValue);
      if (parsed != null && parsed > _maxCount) {
        _showLimitAlert();
        setState(() {
          _counts[key] = _maxCount;
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
      _counts[key] = next;
      ctrl.text    = next.toString();
    });
  }

  void _showRemedySheet(_ExpiationType type) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _RemedySheet(type: type),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) Navigator.pop(context, _grandTotal);
      },
      child: Scaffold(
        backgroundColor: _bgColor,
        body: Stack(
          children: [
            Positioned(
              top: -60, right: -60,
              child: _Blob(size: 220, color: _expiationColor.withValues(alpha: 0.06)),
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

                    // ── App bar ──────────────────────────────────
                    _AnimatedEntry(
                      fade: _fadeAnims[0],
                      slide: _slideAnims[0],
                      child: Row(
                        children: [
                          _BackBtn(onTap: () => Navigator.pop(context, _grandTotal)),
                          const Spacer(),
                          const Text(
                            'Expiations to Give',
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

                    // ── Summary card ─────────────────────────────
                    _AnimatedEntry(
                      fade: _fadeAnims[1],
                      slide: _slideAnims[1],
                      child: _SummaryCard(total: _grandTotal),
                    ),

                    const SizedBox(height: 28),

                    // Section label
                    _AnimatedEntry(
                      fade: _fadeAnims[2],
                      slide: _slideAnims[2],
                      child: Row(
                        children: [
                          Text(
                            'KAFFARAH TYPES',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _subtleText.withValues(alpha: 0.55),
                              letterSpacing: 1.8,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Tooltip(
                            message: 'Tap the ⓘ on any card to see how to fulfil it',
                            child: Icon(
                              Icons.info_outline_rounded,
                              size: 13,
                              color: _subtleText.withValues(alpha: 0.35),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── Expiation cards ──────────────────────────
                    ...List.generate(_expiationTypes.length, (i) {
                      final type  = _expiationTypes[i];
                      final count = _counts[type.key]!;
                      return _AnimatedEntry(
                        fade: _fadeAnims[i + 3],
                        slide: _slideAnims[i + 3],
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _ExpiationCard(
                            type:        type,
                            count:       count,
                            controller:  _controllers[type.key]!,
                            onIncrement: () => _change(type.key, 1),
                            onDecrement: () => _change(type.key, -1),
                            onChanged:   (v) => _change(type.key, 0, rawValue: v),
                            onSubmitted: (v) {
                              if (int.tryParse(v) == null) {
                                setState(() {
                                  _counts[type.key] = 0;
                                  _controllers[type.key]!.text = '0';
                                });
                              }
                            },
                            onInfoTap: () => _showRemedySheet(type),
                          ),
                        ),
                      );
                    }),
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
  const _SummaryCard({required this.total});
  final int total;

  @override
  Widget build(BuildContext context) {
    final allClear = total == 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _expiationColor.withValues(alpha: 0.13),
            _expiationColor.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _expiationColor.withValues(alpha: 0.20),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _expiationColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              allClear
                  ? Icons.check_circle_outline_rounded
                  : Icons.volunteer_activism_rounded,
              color: _expiationColor,
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
                      ? 'All expiations fulfilled'
                      : '$total expiation${total == 1 ? '' : 's'} remaining',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _primaryText,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  allClear
                      ? 'MashaAllah — nothing pending.'
                      : 'Tap ⓘ on any card to see how to fulfil it.',
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

// ── Expiation card ────────────────────────────────────────────────────────────

class _ExpiationCard extends StatelessWidget {
  const _ExpiationCard({
    required this.type,
    required this.count,
    required this.controller,
    required this.onIncrement,
    required this.onDecrement,
    required this.onChanged,
    required this.onSubmitted,
    required this.onInfoTap,
  });

  final _ExpiationType         type;
  final int                    count;
  final TextEditingController  controller;
  final VoidCallback           onIncrement;
  final VoidCallback           onDecrement;
  final ValueChanged<String>   onChanged;
  final ValueChanged<String>   onSubmitted;
  final VoidCallback           onInfoTap;

  @override
  Widget build(BuildContext context) {
    final isZero = count == 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _expiationColor.withValues(alpha: isZero ? 0.08 : 0.22),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: _expiationColor.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _expiationColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(type.icon, color: _expiationColor, size: 18),
          ),
          const SizedBox(width: 12),

          // Name & subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        type.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _primaryText,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    // Info button
                    GestureDetector(
                      onTap: onInfoTap,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: _expiationColor.withValues(alpha: 0.55),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  type.arabicTitle,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: _accentGold.withValues(alpha: 0.65),
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Counter
          Row(
            children: [
              _CounterButton(
                icon: Icons.remove_rounded,
                color: _expiationColor,
                onTap: isZero ? null : onDecrement,
              ),
              Container(
                width: 56,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                child: TextField(
                  controller: controller,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isZero
                        ? _subtleText.withValues(alpha: 0.30)
                        : _expiationColor,
                    letterSpacing: -0.3,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    filled: true,
                    fillColor: _expiationColor.withValues(alpha: 0.07),
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
                color: _expiationColor,
                onTap: onIncrement,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Remedy bottom sheet ───────────────────────────────────────────────────────

class _RemedySheet extends StatelessWidget {
  const _RemedySheet({required this.type});
  final _ExpiationType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _subtleText.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: _expiationColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(type.icon, color: _expiationColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _primaryText,
                      ),
                    ),
                    Text(
                      type.arabicTitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: _accentGold.withValues(alpha: 0.7),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),
          Text(
            type.subtitle,
            style: TextStyle(
              fontSize: 13,
              color: _subtleText.withValues(alpha: 0.75),
              height: 1.5,
            ),
          ),

          const SizedBox(height: 20),

          Text(
            'HOW TO FULFIL',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: _subtleText.withValues(alpha: 0.5),
              letterSpacing: 1.6,
            ),
          ),

          const SizedBox(height: 10),

          // Remedy steps
          ...List.generate(type.remedies.length, (i) {
            final isLast = i == type.remedies.length - 1;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    margin: const EdgeInsets.only(top: 1),
                    decoration: BoxDecoration(
                      color: _expiationColor.withValues(alpha: isLast ? 0.06 : 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        isLast && type.remedies.length > 1 ? '★' : '${i + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isLast && type.remedies.length > 1
                              ? _accentGold
                              : _expiationColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      type.remedies[i],
                      style: TextStyle(
                        fontSize: 13.5,
                        color: _primaryText.withValues(alpha: 0.85),
                        height: 1.45,
                        fontWeight: i == 0 ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 8),

          // Footnote
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _accentGold.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _accentGold.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.menu_book_rounded,
                  size: 14,
                  color: _accentGold.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Options are listed in order of preference. If unable to fulfil one, proceed to the next.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: _subtleText.withValues(alpha: 0.8),
                      height: 1.45,
                    ),
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
          width: 36, height: 36,
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