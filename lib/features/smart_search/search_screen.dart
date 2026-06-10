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

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController controller = TextEditingController();

  bool isLoading = false;
  List<Map<String, dynamic>> results = [];

  // =====================================================
  // 🔍 SEARCH WITH AI (REAL + SAFE)
  // =====================================================
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
      final aiResponse = await AIService.chat(
        """
Find real online stores selling "$query".

Return ONLY valid JSON like this:
[
  {
    "store": "Store name",
    "price": 100,
    "score": 85
  }
]

Rules:
- real data only
- no explanations
- no text outside JSON
"""
      );

      final parsed = _parseResults(aiResponse);

      if (parsed.isEmpty) {
        Helpers.showSnackBar(context, "No results found", isError: true);
      }

      setState(() {
        results = parsed;
      });
    } catch (e) {
      Helpers.showSnackBar(context, "Search failed ❌", isError: true);
    } finally {
      setState(() => isLoading = false);
    }
  }

  // =====================================================
  // 🧠 SAFE PARSER (NO FAKE DATA)
  // =====================================================
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

  // =====================================================
  // 🎨 SCORE COLOR
  // =====================================================
  Color getColor(int score) {
    if (score > 80) return AppColors.trustHigh;
    if (score > 50) return AppColors.trustMedium;
    return AppColors.trustLow;
  }

  // =====================================================
  // 🧱 RESULT CARD
  // =====================================================
  Widget buildResult(Map<String, dynamic> item) {
    final score = item["score"] as int;

    return CustomCard(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // 🏪 STORE
          Text(
            item["store"],
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          // 💰 PRICE
          Text(
            "\$${item["price"]}",
            style: const TextStyle(color: Colors.grey),
          ),

          const SizedBox(height: 10),

          // 📊 SCORE
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Trust Score"),
              Text(
                "$score%",
                style: TextStyle(
                  color: getColor(score),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 6,
              backgroundColor: Colors.grey.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation(getColor(score)),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // UI
  // =====================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Smart Search"),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [

                // 🔥 HEADER
                CustomCard(
                  gradient: AppColors.primaryGradient,
                  child: const Row(
                    children: [
                      Icon(Icons.search, color: Colors.white),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Find trusted stores with best prices",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 🔍 INPUT
                CustomCard(
                  child: Column(
                    children: [
                      TextField(
                        controller: controller,
                        decoration: const InputDecoration(
                          labelText: "Product name",
                        ),
                        onSubmitted: (_) => searchProduct(),
                      ),

                      const SizedBox(height: 15),

                      CustomButton(
                        text: "Search",
                        icon: Icons.search,
                        isLoading: isLoading,
                        onPressed: searchProduct,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 📦 RESULTS
                if (results.isNotEmpty)
                  Expanded(
                    child: ListView.builder(
                      itemCount: results.length,
                      itemBuilder: (_, i) => buildResult(results[i]),
                    ),
                  )
                else if (!isLoading)
                  const Expanded(
                    child: Center(
                      child: Text(
                        "No results yet",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ⏳ LOADING OVERLAY
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