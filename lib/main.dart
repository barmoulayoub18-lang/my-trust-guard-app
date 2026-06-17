import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/constants/colors.dart';
import 'data/services/supabase_service.dart';
import 'features/splash/splash_screen.dart';
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
import 'features/store/screens/admin_dashboard_screen.dart';
import 'features/store/screens/add_product_screen.dart';

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
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const AuthScreen(),
        '/link_scanner': (context) => const LinkScannerScreen(),
        '/panic_mode': (context) => const PanicModeScreen(),
        '/wallet': (context) => const WalletScreen(),
        '/ai_assistant': (context) => const AssistantScreen(),
        '/analysis': (context) => const AnalysisScreen(),
        '/complaints': (context) => const ComplaintsScreen(),
        '/smart_search': (context) => const SearchScreen(),
        '/trust_score': (context) =>
            const TrustScreen(score: 0, details: {}),
        '/store': (context) => const StoreScreen(),
        '/cart': (context) => const CartScreen(),
        '/admin_dashboard': (context) => const AdminDashboardScreen(),
        '/add_product': (context) => const AddProductScreen(),
      },
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
              "App failed to start\n\n$error",
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}