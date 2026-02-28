import 'package:flutter/material.dart';
import '../models/debt_entry.dart';
import '../services/supabase_service.dart';
import 'auth_screen.dart';
import 'debt_screen.dart';
import 'expiations_screen.dart';
import 'fasts_screen.dart';
import 'prayers_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<Animation<double>> _fadeAnims = [];
  List<Animation<Offset>> _slideAnims = [];
  final SupabaseService _supabaseService = SupabaseService();
  bool _isSyncing = false;

  // State management for tracking
  final Map<String, int> _prayerCounts = {
    'Fajr': 0,
    'Zuhr': 0,
    'Asr': 0,
    'Maghrib': 0,
    'Isha': 0,
    'Witr': 0,
  };

  int _fastCount = 0;
  int _expiationsCount = 0;
  List<DebtEntry> _debts = [];

  int get _totalRemaining {
    return _prayerCounts.values.fold(0, (sum, value) => sum + value);
  }

  double get _totalDebt {
    return _debts.fold(0.0, (sum, debt) => sum + debt.amount);
  }

  // Feature cards data
  List<_FeatureItem> get _features => [
    _FeatureItem(
      icon: Icons.mosque,
      label: 'Missed Prayers',
      color: const Color(0xFFB5835A),
      count: '$_totalRemaining',
    ),
    _FeatureItem(
      icon: Icons.no_meals_rounded,
      label: 'Missed Fasts',
      color: const Color(0xFF7A9E7E),
      count: '$_fastCount',
    ),
    _FeatureItem(
      icon: Icons.volunteer_activism_rounded,
      label: 'Expiations',
      color: const Color(0xFF6B8CAE),
      count: '$_expiationsCount',
    ),
    _FeatureItem(
      icon: Icons.account_balance_wallet_rounded,
      label: 'Debt to Pay',
      color: const Color(0xFFA0748A),
      count: 'Rs ${_totalDebt.toStringAsFixed(0)}',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // Staggered animations: title (0), subtitle (1), section (2), cards (3-4), footer (5)
    _fadeAnims = List.generate(6, (i) {
      final start = i * 0.10;
      final end = (start + 0.35).clamp(0.0, 1.0);
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });

    _slideAnims = List.generate(6, (i) {
      final start = i * 0.10;
      final end = (start + 0.35).clamp(0.0, 1.0);
      return Tween<Offset>(
        begin: const Offset(0, 0.25),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });

    _controller.forward();
    _initializeCloudSync();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _navigateToScreen(int index) async {
    switch (index) {
      case 0: // Prayers
        final result = await Navigator.push<Map<String, int>?>(
          context,
          MaterialPageRoute(
            builder: (context) => PrayersScreen(initialCounts: _prayerCounts),
          ),
        );
        if (result != null) {
          setState(() {
            _prayerCounts
              ..clear()
              ..addAll(result);
          });
          await _supabaseService.savePrayers(_prayerCounts);
        }
        break;
      case 1: // Fasts
        final result = await Navigator.push<int?>(
          context,
          MaterialPageRoute(
            builder: (context) => FastsScreen(initialCount: _fastCount),
          ),
        );
        if (result != null) {
          setState(() {
            _fastCount = result;
          });
          await _supabaseService.saveFasts(_fastCount);
        }
        break;
      case 2: // Expiations
        final result = await Navigator.push<int?>(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ExpiationsScreen(initialCount: _expiationsCount),
          ),
        );
        if (result != null) {
          setState(() {
            _expiationsCount = result;
          });
          await _supabaseService.saveExpiations(_expiationsCount);
        }
        break;
      case 3: // Debt
        final result = await Navigator.push<List<DebtEntry>?>(
          context,
          MaterialPageRoute(
            builder: (context) => DebtScreen(initialDebts: _debts),
          ),
        );
        if (result != null) {
          setState(() {
            _debts = result;
          });
          await _supabaseService.saveDebts(_debts);
        }
        break;
    }
  }

  Future<void> _initializeCloudSync() async {
    setState(() {
      _isSyncing = true;
    });

    final prayers = await _supabaseService.getPrayers();
    final fasts = await _supabaseService.getFasts();
    final expiations = await _supabaseService.getExpiations();
    final debts = await _supabaseService.getDebts();

    if (!mounted) {
      return;
    }

    setState(() {
      _prayerCounts
        ..clear()
        ..addAll(prayers);
      _fastCount = fasts;
      _expiationsCount = expiations;
      _debts = debts;
      _isSyncing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFFAF7F4);
    const primaryText = Color(0xFF2D2016);
    const subtleText = Color(0xFF7A6A55);
    const accentGold = Color(0xFFC4954A);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton(
              onPressed: () async {
                await _supabaseService.signOut();
                if (!mounted) return;
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Logout',
                    style: TextStyle(color: primaryText),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.logout, color: primaryText),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── Decorative geometric background ──────────────────────
          Positioned(
            top: -60,
            right: -60,
            child: _GeometricCircle(
              size: 260,
              color: accentGold.withValues(alpha: 0.07),
            ),
          ),
          Positioned(
            top: 80,
            right: 30,
            child: _GeometricCircle(
              size: 100,
              color: accentGold.withValues(alpha: 0.05),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: _GeometricCircle(
              size: 300,
              color: const Color(0xFF7A9E7E).withValues(alpha: 0.06),
            ),
          ),

          // ── Main content ─────────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),

                  // Title
                  _AnimatedEntry(
                    fade: _fadeAnims[0],
                    slide: _slideAnims[0],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hisab',
                          style: TextStyle(
                            fontSize: 52,
                            fontWeight: FontWeight.w800,
                            color: primaryText,
                            height: 1.0,
                            letterSpacing: -1.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'حساب',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w400,
                            color: accentGold.withValues(alpha: 0.75),
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Subtitle
                  _AnimatedEntry(
                    fade: _fadeAnims[1],
                    slide: _slideAnims[1],
                    child: Text(
                      'Track your missed prayers, fasts,\nexpiations, and debts — all in one place.',
                      style: TextStyle(
                        fontSize: 15.5,
                        color: subtleText,
                        height: 1.6,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Section label
                  _AnimatedEntry(
                    fade: _fadeAnims[2],
                    slide: _slideAnims[2],
                    child: Text(
                      'What you can track',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: subtleText.withValues(alpha: 0.7),
                        letterSpacing: 1.4,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Feature cards grid
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 1.0,
                    children: List.generate(_features.length, (i) {
                      final animIndex = 3 + (i ~/ 2).clamp(0, 1);
                      return _AnimatedEntry(
                        fade: _fadeAnims[animIndex],
                        slide: _slideAnims[animIndex],
                        child: _FeatureCard(
                          item: _features[i],
                          onTap: () => _navigateToScreen(i),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 20),

                  if (_isSyncing)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Center(child: CircularProgressIndicator()),
                    ),

                  // Subtle footer note
                  _AnimatedEntry(
                    fade: _fadeAnims[5],
                    slide: _slideAnims[5],
                    child: Center(
                      child: Text(
                        'Your data is securely synced to the cloud.',
                        style: TextStyle(
                          fontSize: 12,
                          color: subtleText.withValues(alpha: 0.55),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

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

class _GeometricCircle extends StatelessWidget {
  const _GeometricCircle({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _FeatureItem {
  const _FeatureItem({
    required this.icon,
    required this.label,
    required this.color,
    this.count,
  });
  final IconData icon;
  final String label;
  final Color color;
  final String? count;
}

class _FeatureCard extends StatefulWidget {
  const _FeatureCard({required this.item, required this.onTap});
  final _FeatureItem item;
  final VoidCallback onTap;

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.item.color;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _pressed ? color.withValues(alpha: 0.12) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withValues(alpha: 0.15),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.item.icon, color: color, size: 22),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.item.label,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D2016),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.item.count ?? '0',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: color.withValues(alpha: 0.8),
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
}
