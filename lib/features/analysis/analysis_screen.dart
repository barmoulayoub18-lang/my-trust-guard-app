import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/helpers.dart';
import '../../data/services/supabase_service.dart';
import '../../data/services/api_service.dart';
import '../../presentation/widgets/custom_card.dart';
import '../../presentation/widgets/custom_button.dart';
import '../../presentation/widgets/loading_widget.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController controller = TextEditingController();

  bool isLoading = false;
  double? score;
  String? risk;
  Map<String, dynamic>? details;
  String? explanation;

  late AnimationController _anim;

  @override
  void initState() {
    super.initState();

    debugPrint("🚀 AnalysisScreen initialized");

    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    debugPrint("🧹 AnalysisScreen disposed");
    _anim.dispose();
    controller.dispose();
    super.dispose();
  }

  Future<void> analyzeStore() async {
    final input = controller.text.trim();

    debugPrint("🟡 STEP 1: User input = $input");

    if (input.isEmpty) {
      debugPrint("❌ ERROR: Empty input");
      Helpers.showSnackBar(context, "Enter store link or name", isError: true);
      return;
    }

    setState(() {
      isLoading = true;
      score = null;
    });

    debugPrint("🟡 STEP 2: Loading started");

    try {
      debugPrint("🟡 STEP 3: Calling API...");

      final result = await ApiService.analyze(input);

      debugPrint("🟢 STEP 4: API response received");
      debugPrint("📦 RESULT = $result");

      final resultScore = (result["score"] ?? 0).toDouble();

      debugPrint("🟢 STEP 5: Score parsed = $resultScore");

      String riskLevel;
      if (resultScore > 80) {
        riskLevel = "Low Risk";
      } else if (resultScore > 50) {
        riskLevel = "Medium Risk";
      } else {
        riskLevel = "High Risk";
      }

      debugPrint("🟢 STEP 6: Risk level = $riskLevel");

      final resultDetails = {
        "reviews": result["reviews"] ?? "Unknown",
        "activity": result["activity"] ?? "Unknown",
      };

      debugPrint("🟢 STEP 7: Details parsed = $resultDetails");

      _saveAnalysisBackground(input, resultScore, resultDetails);

      setState(() {
        score = resultScore;
        risk = riskLevel;
        details = resultDetails;
        explanation = result["explanation"] ?? result["reason"];
      });

      debugPrint("🟢 STEP 8: UI updated");

      _anim.forward(from: 0);

      debugPrint("🟢 STEP 9: Animation triggered");
    } catch (e, stack) {
      debugPrint("❌ ERROR IN ANALYSIS");
      debugPrint("❌ MESSAGE: $e");
      debugPrint("❌ STACK: $stack");

      Helpers.showSnackBar(context, e.toString(), isError: true);
    } finally {
      setState(() {
        isLoading = false;
      });

      debugPrint("🟡 STEP 10: Loading finished");
    }
  }

  void _saveAnalysisBackground(
    String storeId,
    double score,
    Map<String, dynamic> details,
  ) {
    debugPrint("🟡 BACKGROUND SAVE START");

    Future(() async {
      try {
        await SupabaseService.saveAnalysis(
          storeId: storeId,
          score: score,
          details: details,
        );

        debugPrint("🟢 BACKGROUND SAVE SUCCESS");
      } catch (e) {
        debugPrint("❌ BACKGROUND SAVE FAILED: $e");
      }
    });
  }

  Color getRiskColor() {
    if (score == null) return Colors.grey;
    if (score! > 80) return AppColors.trustHigh;
    if (score! > 50) return AppColors.trustMedium;
    return AppColors.trustLow;
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("🎨 UI BUILD CALLED");

    return Scaffold(
      appBar: AppBar(title: const Text("AI Store Analysis")),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                CustomCard(
                  child: Column(
                    children: [
                      TextField(
                        controller: controller,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: "Store URL or Name",
                        ),
                      ),
                      const SizedBox(height: 15),
                      CustomButton(
                        text: "Analyze Now",
                        icon: Icons.analytics,
                        isLoading: isLoading,
                        onPressed: analyzeStore,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                if (score != null)
                  FadeTransition(
                    opacity: _anim,
                    child: Column(
                      children: [
                        CustomCard(
                          gradient: LinearGradient(
                            colors: [
                              getRiskColor().withOpacity(0.9),
                              getRiskColor().withOpacity(0.6),
                            ],
                          ),
                          padding: 24,
                          child: Column(
                            children: [
                              Text(
                                "${score!.toInt()}%",
                                style: const TextStyle(
                                  fontSize: 50,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                risk ?? "",
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        CustomCard(
                          child: Column(
                            children: [
                              buildDetail("Reviews", details?["reviews"]),
                              buildDetail("Activity", details?["activity"]),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (explanation != null)
                          CustomCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "AI Explanation",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  constraints: const BoxConstraints(
                                    maxHeight: 160,
                                  ),
                                  child: Scrollbar(
                                    thumbVisibility: true,
                                    child: SingleChildScrollView(
                                      child: Text(
                                        explanation!,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          height: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (isLoading)
            const LoadingWidget(
              isFullScreen: true,
              text: "Analyzing real market data...",
            ),
        ],
      ),
    );
  }

  Widget buildDetail(String title, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 6),
          Container(
            constraints: const BoxConstraints(maxHeight: 100),
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                child: Text(
                  value ?? "",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
