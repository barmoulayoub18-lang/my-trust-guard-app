import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/constants/colors.dart';
import 'data/services/supabase_service.dart';
import 'features/home/home_screen.dart';
import 'features/auth/auth_screen.dart';
import 'features/store/providers/store_provider.dart';
import 'features/store/providers/cart_provider.dart';

import 'features/link_scanner/link_scanner_screen.dart';
import 'features/panic_mode/panic_mode_screen.dart';
import 'features/safe_payment/wallet_screen.dart';
import 'features/ai_assistant/assistant_screen.dart';
import 'features/analysis/analysis_screen.dart';
import 'features/complaints/complaints_screen.dart';
import 'features/smart_search/search_screen.dart';
import 'features/trust_score/trust_screen.dart';
import 'features/store/screens/store_screen.dart';
import 'features/store/screens/cart_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
    await SupabaseService.init();
    runApp(const ProviderScope(child: MyApp()));
  } catch (e) {
    runApp(ErrorApp(error: e.toString()));
  }
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(storeProvider.notifier).loadProducts();
      ref.read(cartProvider.notifier).loadCart();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'trust_guard_app',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: const AuthWrapper(),
      routes: {
        '/link_scanner': (context) => const LinkScannerScreen(),
        '/panic_mode': (context) => const PanicModeScreen(),
        '/wallet': (context) => const WalletScreen(),
        '/ai_assistant': (context) => const AssistantScreen(),
        '/analysis': (context) => const AnalysisScreen(),
        '/complaints': (context) => const ComplaintsScreen(),
        '/smart_search': (context) => const SearchScreen(),
        '/trust_score': (context) =>
            const TrustScreen(score: 0, details: const {}),
        '/store': (context) => const StoreScreen(),
        '/cart': (context) => const CartScreen(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: SupabaseService.authState,
      builder: (context, snapshot) {
        final currentSession = SupabaseService.client.auth.currentSession;

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        if (currentSession != null) {
          return const HomeScreen();
        }

        return const AuthScreen();
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _scale = Tween(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.4),
                        blurRadius: 20,
                      )
                    ],
                  ),
                  child: const Icon(
                    Icons.security_rounded,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 25),
                const Text(
                  "trust_guard_app",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "AI Protection for Smart Shopping",
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ErrorApp extends StatelessWidget {
  final String error;

  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              "❌ App failed to start\n\n$error",
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
