import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
import '../store/screens/store_screen.dart';
import '../link_scanner/link_scanner_screen.dart';
import '../panic_mode/panic_mode_screen.dart';
import '../safe_payment/wallet_screen.dart';
import '../trust_score/trust_screen.dart';
import '../store/screens/cart_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();

    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(profileProvider.notifier).loadProfile();
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void navigate(Widget screen) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, __, ___) => screen,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("trust_guard_app"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_rounded),
            onPressed: () => navigate(const CartScreen()),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              ref.read(profileProvider.notifier).clear();
            },
          )
        ],
      ),
      body: FadeTransition(
        opacity: _anim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(name),
              const SizedBox(height: 20),
              _buildHeroCard(),
              const SizedBox(height: 25),
              _buildFeaturesGrid(),
              const SizedBox(height: 25),
              _buildAlert(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String name) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Welcome back 👋",
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          name,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard() {
    return CustomCard(
      gradient: AppColors.primaryGradient,
      padding: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "AI Protection Active",
            style: TextStyle(color: Colors.white70),
          ),
          SizedBox(height: 10),
          Text(
            "Real-time Scam Detection",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 6),
          Text(
            "  Real Market Data",
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesGrid() {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.05,
      ),
      children: [
        _featureCard(
          title: "Analyze Store",
          icon: Icons.analytics_rounded,
          color: AppColors.primary,
          onTap: () => navigate(const AnalysisScreen()),
        ),
        _featureCard(
          title: "Smart Search",
          icon: Icons.search_rounded,
          color: Colors.orange,
          onTap: () => navigate(const SearchScreen()),
        ),
        _featureCard(
          title: "Store Marketplace",
          icon: Icons.store_rounded,
          color: Colors.blue,
          onTap: () => navigate(const StoreScreen()),
        ),
        _featureCard(
          title: "AI Assistant",
          icon: Icons.smart_toy_rounded,
          color: Colors.purple,
          onTap: () => navigate(const AssistantScreen()),
        ),
        _featureCard(
          title: "Link Scanner",
          icon: Icons.link_rounded,
          color: Colors.teal,
          onTap: () => navigate(const LinkScannerScreen()),
        ),
        _featureCard(
          title: "Emergency Panic",
          icon: Icons.gpp_bad_rounded,
          color: Colors.red,
          onTap: () => navigate(const PanicModeScreen()),
        ),
        _featureCard(
          title: "Secure Wallet",
          icon: Icons.account_balance_wallet_rounded,
          color: Colors.green,
          onTap: () => navigate(const WalletScreen()),
        ),
        _featureCard(
          title: "Trust Score",
          icon: Icons.verified_user_rounded,
          color: Colors.indigo,
          onTap: () => navigate(const TrustScreen(score: 0, details: {})),
        ),
        _featureCard(
          title: "Report Store",
          icon: Icons.report_rounded,
          color: Colors.redAccent,
          onTap: () => navigate(const ComplaintsScreen()),
        ),
      ],
    );
  }

  Widget _featureCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return CustomCard(
      onTap: onTap,
      padding: 18,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.25),
                  color.withOpacity(0.1),
                ],
              ),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlert() {
    return CustomCard(
      child: Row(
        children: const [
          Icon(Icons.warning_amber_rounded, color: Colors.orange),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "AI analyzes real public data. Always verify sellers before purchasing.",
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}