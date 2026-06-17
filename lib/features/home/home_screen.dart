import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import '../../core/constants/colors.dart';
import '../../data/services/supabase_service.dart';
import '../../presentation/widgets/custom_card.dart';
import '../../presentation/widgets/loading_widget.dart';

import '../analysis/analysis_screen.dart';
import '../ai_assistant/assistant_screen.dart';
import '../smart_search/search_screen.dart';
import '../complaints/complaints_screen.dart';
import '../profile/profile_provider.dart';
import '../auth/auth_provider.dart';
import '../auth/auth_screen.dart';
import '../store/screens/store_screen.dart';
import '../link_scanner/link_scanner_screen.dart';
import '../panic_mode/panic_mode_screen.dart';
import '../safe_payment/wallet_screen.dart';
import '../safe_payment/payment_screen.dart';
import '../trust_score/trust_screen.dart';
import '../store/screens/cart_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainAnimController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late AnimationController _pulseController;
  final Map<int, bool> _hoverStates = {};

  @override
  void initState() {
    super.initState();

    _mainAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainAnimController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.93, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainAnimController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutBack),
      ),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _mainAnimController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(profileProvider.notifier).loadProfile();
    });
  }

  @override
  void dispose() {
    _mainAnimController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void navigate(Widget screen) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        reverseTransitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, __, ___) => screen,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final user = SupabaseService.currentUser;
    final email = user?.email ?? "User";
    final name = profileState.profile?['name'] ?? email;

    if (profileState.isLoading) {
      return const Scaffold(
        body: LoadingWidget(
          isFullScreen: true,
          text: "Loading your dashboard...",
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.white,
            title: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: const Text(
                "trust_guard_app",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                  letterSpacing: -0.5,
                  color: Colors.white,
                ),
              ),
            ),
            centerTitle: false,
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined, color: Color(0xFF334155), size: 22),
                  onPressed: () => navigate(const CartScreen()),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(right: 16),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.power_settings_new_rounded, color: Color(0xFFEF4444), size: 22),
                  onPressed: () async {
                    ref.read(profileProvider.notifier).clear();
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const AuthScreen()),
                        (route) => false,
                      );
                    }
                  },
                ),
              )
            ],
          ),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(name),
                      const SizedBox(height: 24),
                      _buildHeroCard(),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 18,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            "Security Platform Features",
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E293B),
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildFeaturesGrid(),
                      const SizedBox(height: 32),
                      _buildAlert(),
                      const SizedBox(height: 40),
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

  Widget _buildHeader(String name) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "SYSTEM DASHBOARD",
              style: TextStyle(
                color: Color(0xFF3B82F6),
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              name,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                letterSpacing: -0.8,
              ),
            ),
          ],
        ),
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withOpacity(0.1 + (_pulseController.value * 0.05)),
                    blurRadius: 10,
                    spreadRadius: _pulseController.value * 3,
                  ),
                ],
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    "SECURE",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF10B981),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHeroCard() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: LinearGradient(
              colors: const [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF2563EB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [0.0, 0.5, 1.0 + (_pulseController.value * 0.1)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB).withOpacity(0.25),
                blurRadius: 25,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                top: -20,
                child: Icon(
                  Icons.gpp_good_rounded,
                  size: 150,
                  color: Colors.white.withOpacity(0.04),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF60A5FA).withOpacity(0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.auto_awesome_rounded, color: Color(0xFF93C5FD), size: 14),
                            SizedBox(width: 6),
                            Text(
                              "AI Protection Active",
                              style: TextStyle(
                                color: Color(0xFF93C5FD),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Real-time Scam\nDetection Systems",
                    style: TextStyle(
                      fontSize: 26,
                      height: 1.2,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Icon(Icons.layers_outlined, color: Colors.white.withOpacity(0.6), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        "Real Market Data Stream Connected",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeaturesGrid() {
    final List<Map<String, dynamic>> features = [
      {
        "title": "Analyze",
        "icon": Icons.analytics_rounded,
        "color": const Color(0xFF2563EB),
        "onTap": () => navigate(const AnalysisScreen()),
      },
      {
        "title": "Link Scanner",
        "icon": Icons.link_rounded,
        "color": const Color(0xFF0D9488),
        "onTap": () => navigate(const LinkScannerScreen()),
      },
      {
        "title": "Store Marketplace",
        "icon": Icons.store_rounded,
        "color": const Color(0xFF0284C7),
        "onTap": () => navigate(const StoreScreen()),
      },
      {
        "title": "AI Assistant",
        "icon": Icons.smart_toy_rounded,
        "color": const Color(0xFF7C3AED),
        "onTap": () => navigate(const AssistantScreen()),
      },

      
      

      {
        "title": "Emergency Panic",
        "icon": Icons.gpp_bad_rounded,
        "color": const Color(0xFFDC2626),
        "onTap": () => navigate(const PanicModeScreen()),
      },
      {
        "title": "Secure Wallet",
        "icon": Icons.account_balance_wallet_rounded,
        "color": const Color(0xFF16A34A),
        "onTap": () => navigate(const WalletScreen()),
      },
      {
        "title": "Escrow Sandbox Pay",
        "icon": Icons.payment_rounded,
        "color": const Color(0xFFD97706),
        "onTap": () => navigate(const PaymentScreen()),
      },
      {
        "title": "Trust Score",
        "icon": Icons.verified_user_rounded,
        "color": const Color(0xFF4F46E5),
        "onTap": () => navigate(const TrustScreen(score: 0, details: {})),
      },
      {
        "title": "Report Store",
        "icon": Icons.report_rounded,
        "color": const Color(0xFFE11D48),
        "onTap": () => navigate(const ComplaintsScreen()),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: features.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.15,
      ),
      itemBuilder: (context, index) {
        final item = features[index];
        return _featureCard(
          id: index,
          title: item["title"],
          icon: item["icon"],
          color: item["color"],
          onTap: item["onTap"],
        );
      },
    );
  }

  Widget _featureCard({
    required int id,
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isHovered = _hoverStates[id] ?? false;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoverStates[id] = true),
      onExit: (_) => setState(() => _hoverStates[id] = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _hoverStates[id] = true),
        onTapUp: (_) => setState(() => _hoverStates[id] = false),
        onTapCancel: () => setState(() => _hoverStates[id] = false),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          transform: isHovered ? Matrix4.translationValues(0, -6, 0) : Matrix4.identity(),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isHovered ? color.withOpacity(0.3) : const Color(0xFFE2E8F0),
              width: isHovered ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isHovered ? color.withOpacity(0.12) : const Color(0xFF0F172A).withOpacity(0.03),
                blurRadius: isHovered ? 20 : 12,
                offset: isHovered ? const Offset(0, 8) : const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isHovered ? color : color.withOpacity(0.08),
                  ),
                  child: Icon(
                    icon,
                    color: isHovered ? Colors.white : color,
                    size: 24,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Color(0xFF1E293B),
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: isHovered ? color : const Color(0xFF94A3B8),
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlert() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFFBBF24).withOpacity(0.3 + (_pulseController.value * 0.2)),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD97706).withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.privacy_tip_outlined, color: Color(0xFFD97706), size: 20),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "System Notice",
                      style: TextStyle(
                        color: Color(0xFF92400E),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "AI analyzes real public data. Always verify sellers before purchasing.",
                      style: TextStyle(
                        color: Color(0xFFB45309),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}