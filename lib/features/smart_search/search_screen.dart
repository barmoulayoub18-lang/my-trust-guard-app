import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/helpers.dart';
import '../../data/services/ai_service.dart';
import '../../presentation/widgets/custom_card.dart';
import '../../presentation/widgets/custom_button.dart';
import '../../presentation/widgets/loading_widget.dart';
import 'dart:convert';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController controller = TextEditingController();
  late final AnimationController _pulseController;
  int? hoveredIndex;

  bool isLoading = false;
  List<Map<String, dynamic>> results = [];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    controller.dispose();
    super.dispose();
  }

  Future<void> searchProduct() async {
    final query = controller.text.trim();

    if (query.isEmpty) {
      Helpers.showSnackBar(context, "Enter product name", isError: true);
      return;
    }

    setState(() {
      isLoading = true;
      results = [];
    });

    try {
      final aiResponse = await AIService.chat("""
Find exactly 15 real online stores selling "$query".

Return ONLY valid JSON like this:
[
  {
    "store": "Store name",
    "price": 100,
    "score": 85
  }
]

Rules:
- Provide exactly 15 different real stores if available
- real data only
- no explanations
- no text outside JSON
""");

      final parsed = _parseResults(aiResponse);

      if (parsed.isEmpty) {
        Helpers.showSnackBar(context, "No results found", isError: true);
      }

      setState(() {
        results = parsed;
      });
    } catch (e) {
      Helpers.showSnackBar(context, "Search failed", isError: true);
    } finally {
      setState(() => isLoading = false);
    }
  }

  List<Map<String, dynamic>> _parseResults(String text) {
    try {
      final start = text.indexOf('[');
      final end = text.lastIndexOf(']') + 1;

      if (start == -1 || end == -1) return [];

      final jsonString = text.substring(start, end);

      final List list = jsonDecode(jsonString);

      return list.map<Map<String, dynamic>>((e) {
        return {
          "store": e["store"]?.toString() ?? "Unknown",
          "price": (e["price"] ?? 0).toDouble(),
          "score": (e["score"] ?? 50).toInt(),
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Color getColor(int score) {
    if (score > 80) return AppColors.trustHigh;
    if (score > 50) return AppColors.trustMedium;
    return AppColors.trustLow;
  }

  Widget buildResult(Map<String, dynamic> item, int index) {
    final score = item["score"] as int;
    final isHovered = hoveredIndex == index;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (index * 40)),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1.0 - value)),
            child: child,
          ),
        );
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => hoveredIndex = index),
        onExit: (_) => setState(() => hoveredIndex = null),
        child: AnimatedRotation(
          duration: const Duration(milliseconds: 200),
          turns: isHovered ? 0.002 : 0.0,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 250),
            scale: isHovered ? 1.02 : 1.0,
            curve: Curves.easeOutBack,
            child: CustomCard(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(18.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: isHovered
                      ? LinearGradient(
                          colors: [
                            AppColors.surface,
                            getColor(score).withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  border: Border.all(
                    color: isHovered
                        ? getColor(score).withOpacity(0.4)
                        : getColor(score).withOpacity(0.12),
                    width: isHovered ? 1.5 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isHovered
                          ? getColor(score).withOpacity(0.08)
                          : Colors.black.withOpacity(0.01),
                      blurRadius: isHovered ? 12 : 4,
                      offset:
                          isHovered ? const Offset(0, 4) : const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: getColor(score).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.storefront_rounded,
                                  color: getColor(score),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item["store"],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isHovered
                                ? AppColors.primary.withOpacity(0.05)
                                : AppColors.background,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isHovered
                                  ? AppColors.primary.withOpacity(0.3)
                                  : AppColors.border,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            "\$${item["price"].toStringAsFixed(2)}",
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) {
                                return Opacity(
                                  opacity: isHovered
                                      ? 0.6 + (_pulseController.value * 0.4)
                                      : 1.0,
                                  child: child,
                                );
                              },
                              child: const Icon(
                                Icons.verified_user_outlined,
                                color: AppColors.textSecondary,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              "Trust Score",
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: getColor(score).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "$score%",
                            style: TextStyle(
                              color: getColor(score),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 1000),
                            curve: Curves.easeOutCubic,
                            tween: Tween<double>(begin: 0, end: score / 100),
                            builder: (context, val, _) {
                              return LinearProgressIndicator(
                                value: val,
                                minHeight: 8,
                                backgroundColor: AppColors.border,
                                valueColor:
                                    AlwaysStoppedAnimation(getColor(score)),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Smart Search",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              children: [
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 400),
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, -10 * (1.0 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: CustomCard(
                    gradient: AppColors.primaryGradient,
                    child: Row(
                      children: [
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: 1.0 + (_pulseController.value * 0.12),
                              child: child,
                            );
                          },
                          child: const Icon(Icons.search_rounded,
                              color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            "Find trusted stores with best prices",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 500),
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 10 * (1.0 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: CustomCard(
                    child: Column(
                      children: [
                        TextField(
                          controller: controller,
                          style: const TextStyle(
                              color: AppColors.textPrimary, fontSize: 14),
                          decoration: InputDecoration(
                            labelText: "Product name",
                            labelStyle: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 13),
                            floatingLabelStyle:
                                const TextStyle(color: AppColors.primary),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  const BorderSide(color: AppColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: AppColors.primary, width: 1.5),
                            ),
                            prefixIcon: const Icon(Icons.shopping_bag_outlined,
                                color: AppColors.textSecondary, size: 20),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 14, horizontal: 16),
                          ),
                          onSubmitted: (_) => searchProduct(),
                        ),
                        const SizedBox(height: 16),
                        CustomButton(
                          text: "Search",
                          icon: Icons.search_rounded,
                          isLoading: isLoading,
                          onPressed: searchProduct,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (results.isNotEmpty)
                  Expanded(
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: results.length,
                      itemBuilder: (_, i) => buildResult(results[i], i),
                    ),
                  )
                else if (!isLoading)
                  Expanded(
                    child: Center(
                      child: TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 600),
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        builder: (context, val, child) {
                          return Opacity(
                            opacity: val,
                            child: Transform.scale(
                              scale: 0.8 + (val * 0.2),
                              child: child,
                            ),
                          );
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset:
                                      Offset(0, _pulseController.value * -6),
                                  child: child,
                                );
                              },
                              child: Icon(
                                Icons.manage_search_rounded,
                                size: 54,
                                color:
                                    AppColors.textSecondary.withOpacity(0.25),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "No results yet",
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (isLoading)
            const LoadingWidget(
              isFullScreen: true,
              text: "Searching real data...",
            ),
        ],
      ),
    );
  }
}
