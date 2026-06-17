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

    with TickerProviderStateMixin {

  final TextEditingController controller = TextEditingController();



  bool isLoading = false;

  double? score;

  String? risk;

  Map<String, dynamic>? details;

  String? explanation;



  late AnimationController _anim;

  late AnimationController _pulseAnim;

  late Animation<double> _scaleAnimation;

  late Animation<double> _fadeAnimation;



  @override

  void initState() {

    super.initState();

    _anim = AnimationController(

      vsync: this,

      duration: const Duration(milliseconds: 1000),

    );

    _pulseAnim = AnimationController(

      vsync: this,

      duration: const Duration(milliseconds: 2000),

    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(

      CurvedAnimation(parent: _anim, curve: Curves.elasticOut),

    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(

      CurvedAnimation(parent: _anim, curve: Curves.easeIn),

    );

  }



  @override

  void dispose() {

    _anim.dispose();

    _pulseAnim.dispose();

    controller.dispose();

    super.dispose();

  }



  Future<void> analyzeStore() async {

    final input = controller.text.trim();



    if (input.isEmpty) {

      Helpers.showSnackBar(context, "Enter store link or name", isError: true);

      return;

    }



    setState(() {

      isLoading = true;

      score = null;

    });



    try {

      final result = await ApiService.analyze(input);



      final resultScore = (result["score"] ?? 0).toDouble();



      String riskLevel;

      if (resultScore > 80) {

        riskLevel = "Low Risk";

      } else if (resultScore > 50) {

        riskLevel = "Medium Risk";

      } else {

        riskLevel = "High Risk";

      }



      final resultDetails = {

        "reviews": result["reviews"] ?? "Unknown",

        "activity": result["activity"] ?? "Unknown",

      };



      _saveAnalysisBackground(input, resultScore, resultDetails);



      setState(() {

        score = resultScore;

        risk = riskLevel;

        details = resultDetails;

        explanation = result["explanation"] ?? result["reason"];

      });



      _anim.forward(from: 0);

    } catch (e, stack) {

      Helpers.showSnackBar(context, e.toString(), isError: true);

    } finally {

      setState(() {

        isLoading = false;

      });

    }

  }



  void _saveAnalysisBackground(

    String storeId,

    double score,

    Map<String, dynamic> details,

  ) {

    Future(() async {

      try {

        await SupabaseService.saveAnalysis(

          storeId: storeId,

          score: score,

          details: details,

        );

      } catch (e) {

        return;

      }

    });

  }



  Color getRiskColor() {

    if (score == null) return Colors.grey;

    if (score! > 80) return AppColors.trustHigh;

    if (score! > 50) return AppColors.trustMedium;

    return AppColors.trustLow;

  }



  LinearGradient getModernGradient() {

    if (score == null) {

      return const LinearGradient(

        colors: [Color(0xFF64748B), Color(0xFF475569)],

        begin: Alignment.topLeft,

        end: Alignment.bottomRight,

      );

    }

    if (score! > 80) {

      return const LinearGradient(

        colors: [Color(0xFF10B981), Color(0xFF059669)],

        begin: Alignment.topLeft,

        end: Alignment.bottomRight,

      );

    }

    if (score! > 50) {

      return const LinearGradient(

        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],

        begin: Alignment.topLeft,

        end: Alignment.bottomRight,

      );

    }

    return const LinearGradient(

      colors: [Color(0xFFEF4444), Color(0xFFDC2626)],

      begin: Alignment.topLeft,

      end: Alignment.bottomRight,

    );

  }



  IconData getRiskIcon() {

    if (score == null) return Icons.help_outline;

    if (score! > 80) return Icons.gpp_good_rounded;

    if (score! > 50) return Icons.gpp_maybe_rounded;

    return Icons.gpp_bad_rounded;

  }



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xFFF8FAFC),

      appBar: AppBar(

        backgroundColor: Colors.white,

        elevation: 0,

        title: Row(

          children: [

            ScaleTransition(

              scale: _pulseAnim.drive(Tween(begin: 1.0, end: 1.1)),

              child: const Icon(Icons.blur_on_rounded, color: Color(0xFF3B82F6), size: 26),

            ),

            const SizedBox(width: 10),

            const Text(

              "AI Store Analysis",

              style: TextStyle(

                color: Color(0xFF0F172A),

                fontWeight: FontWeight.w900,

                fontSize: 22,

                letterSpacing: -0.5,

              ),

            ),

          ],

        ),

        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),

        shape: const Border(

          bottom: BorderSide(

            color: Color(0xFFE2E8F0),

            width: 1,

          ),

        ),

      ),

      body: Stack(

        children: [

          SingleChildScrollView(

            physics: const BouncingScrollPhysics(),

            padding: const EdgeInsets.all(20),

            child: Column(

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                AnimatedContainer(

                  duration: const Duration(milliseconds: 400),

                  decoration: BoxDecoration(

                    color: Colors.white,

                    borderRadius: BorderRadius.circular(24),

                    boxShadow: [

                      BoxShadow(

                        color: const Color(0xFF0F172A).withOpacity(0.04),

                        blurRadius: 20,

                        offset: const Offset(0, 8),

                      ),

                    ],

                  ),

                  child: CustomCard(

                    color: Colors.transparent,

                    hasShadow: false,

                    padding: 20,

                    child: Column(

                      children: [

                        TextField(

                          controller: controller,

                          style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600),

                          decoration: InputDecoration(

                            labelText: "website URL or Name",

                            labelStyle: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500),

                            hintStyle: const TextStyle(color: Color(0xFF94A3B8)),

                            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF3B82F6)),

                            enabledBorder: OutlineInputBorder(

                              borderRadius: BorderRadius.circular(16),

                              borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),

                            ),

                            focusedBorder: OutlineInputBorder(

                              borderRadius: BorderRadius.circular(16),

                              borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),

                            ),

                            filled: true,

                            fillColor: const Color(0xFFF8FAFC),

                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),

                          ),

                        ),

                        const SizedBox(height: 20),

                        CustomButton(

                          text: "Analyze Now",

                          icon: Icons.bolt_rounded,

                          isLoading: isLoading,

                          onPressed: analyzeStore,

                        ),

                      ],

                    ),

                  ),

                ),

                const SizedBox(height: 30),

                if (score != null)

                  FadeTransition(

                    opacity: _fadeAnimation,

                    child: ScaleTransition(

                      scale: _scaleAnimation,

                      child: Column(

                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [

                          Container(

                            width: double.infinity,

                            decoration: BoxDecoration(

                              gradient: getModernGradient(),

                              borderRadius: BorderRadius.circular(32),

                              boxShadow: [

                                BoxShadow(

                                  color: getRiskColor().withOpacity(0.3),

                                  blurRadius: 25,

                                  offset: const Offset(0, 12),

                                ),

                              ],

                            ),

                            child: CustomCard(

                              color: Colors.transparent,

                              hasShadow: false,

                              padding: 30,

                              child: Column(

                                children: [

                                  Container(

                                    padding: const EdgeInsets.all(16),

                                    decoration: BoxDecoration(

                                      color: Colors.white.withOpacity(0.15),

                                      shape: BoxShape.circle,

                                    ),

                                    child: Icon(

                                      getRiskIcon(),

                                      color: Colors.white,

                                      size: 40,

                                    ),

                                  ),

                                  const SizedBox(height: 20),

                                  Row(

                                    mainAxisAlignment: MainAxisAlignment.center,

                                    crossAxisAlignment: CrossAxisAlignment.baseline,

                                    textBaseline: TextBaseline.alphabetic,

                                    children: [

                                      Text(

                                        "${score!.toInt()}",

                                        style: const TextStyle(

                                          fontSize: 72,

                                          fontWeight: FontWeight.w900,

                                          color: Colors.white,

                                          height: 1.0,

                                        ),

                                      ),

                                      const Text(

                                        "%",

                                        style: TextStyle(

                                          fontSize: 28,

                                          fontWeight: FontWeight.bold,

                                          color: Colors.white70,

                                        ),

                                      ),

                                    ],

                                  ),

                                  const SizedBox(height: 12),

                                  Container(

                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),

                                    decoration: BoxDecoration(

                                      color: Colors.white,

                                      borderRadius: BorderRadius.circular(100),

                                    ),

                                    child: Text(

                                      risk ?? "",

                                      style: TextStyle(

                                        fontSize: 15,

                                        fontWeight: FontWeight.w800,

                                        color: getRiskColor(),

                                        letterSpacing: 0.5,

                                      ),

                                    ),

                                  ),

                                ],

                              ),

                            ),

                          ),

                          const SizedBox(height: 25),

                          const Padding(

                            padding: EdgeInsets.only(left: 8, bottom: 12),

                            child: Text(

                              "METRIC METADATA",

                              style: TextStyle(

                                fontSize: 12,

                                fontWeight: FontWeight.w800,

                                color: Color(0xFF64748B),

                                letterSpacing: 1.5,

                              ),

                            ),

                          ),

                          Container(

                            decoration: BoxDecoration(

                              color: Colors.white,

                              borderRadius: BorderRadius.circular(24),

                              boxShadow: [

                                BoxShadow(

                                  color: const Color(0xFF0F172A).withOpacity(0.02),

                                  blurRadius: 15,

                                  offset: const Offset(0, 5),

                                ),

                              ],

                            ),

                            child: CustomCard(

                              color: Colors.transparent,

                              hasShadow: false,

                              padding: 24,

                              child: Column(

                                children: [

                                  buildDetail("Reviews", details?["reviews"]),

                                  Padding(

                                    padding: const EdgeInsets.symmetric(vertical: 16),

                                    child: Container(height: 1, color: const Color(0xFFF1F5F9)),

                                  ),

                                  buildDetail("Activity", details?["activity"]),

                                ],

                              ),

                            ),

                          ),

                          const SizedBox(height: 25),

                          if (explanation != null) ...[

                            const Padding(

                              padding: EdgeInsets.only(left: 8, bottom: 12),

                              child: Text(

                                "INTELLIGENCE REPORT",

                                style: TextStyle(

                                  fontSize: 12,

                                  fontWeight: FontWeight.w800,

                                  color: Color(0xFF64748B),

                                  letterSpacing: 1.5,

                                ),

                              ),

                            ),

                            Container(

                              decoration: BoxDecoration(

                                color: Colors.white,

                                borderRadius: BorderRadius.circular(24),

                                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),

                              ),

                              child: CustomCard(

                                color: Colors.transparent,

                                hasShadow: false,

                                padding: 24,

                                child: Column(

                                  crossAxisAlignment: CrossAxisAlignment.start,

                                  children: [

                                    Row(

                                      children: [

                                        Icon(Icons.psychology_rounded, color: getRiskColor(), size: 24),

                                        const SizedBox(width: 10),

                                        const Text(

                                          "AI Explanation",

                                          style: TextStyle(

                                            fontWeight: FontWeight.w800,

                                            fontSize: 16,

                                            color: Color(0xFF0F172A),

                                          ),

                                        ),

                                      ],

                                    ),

                                    const SizedBox(height: 16),

                                    Container(

                                      constraints: const BoxConstraints(maxHeight: 200),

                                      child: Scrollbar(

                                        thumbVisibility: true,

                                        radius: const Radius.circular(8),

                                        child: SingleChildScrollView(

                                          physics: const BouncingScrollPhysics(),

                                          child: Padding(

                                            padding: const EdgeInsets.only(right: 12),

                                            child: Text(

                                              explanation!,

                                              style: const TextStyle(

                                                color: Color(0xFF334155),

                                                height: 1.6,

                                                fontSize: 14,

                                                fontWeight: FontWeight.w500,

                                              ),

                                            ),

                                          ),

                                        ),

                                      ),

                                    ),

                                  ],

                                ),

                              ),

                            ),

                          ],

                        ],

                      ),

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

      padding: const EdgeInsets.all(0),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Row(

            children: [

              Container(

                width: 6,

                height: 6,

                decoration: const BoxDecoration(

                  color: Color(0xFF3B82F6),

                  shape: BoxShape.circle,

                ),

              ),

              const SizedBox(width: 8),

              Text(

                title,

                style: const TextStyle(

                  color: Color(0xFF64748B),

                  fontSize: 13,

                  fontWeight: FontWeight.w700,

                  letterSpacing: 0.3,

                ),

              ),

            ],

          ),

          const SizedBox(height: 10),

          Container(

            width: double.infinity,

            padding: const EdgeInsets.all(14),

            decoration: BoxDecoration(

              color: const Color(0xFFF8FAFC),

              borderRadius: BorderRadius.circular(14),

            ),

            constraints: const BoxConstraints(maxHeight: 120),

            child: Scrollbar(

              thumbVisibility: true,

              radius: const Radius.circular(8),

              child: SingleChildScrollView(

                physics: const BouncingScrollPhysics(),

                child: Padding(

                  padding: const EdgeInsets.only(right: 8),

                  child: Text(

                    value ?? "",

                    style: const TextStyle(

                      color: Color(0xFF0F172A),

                      fontWeight: FontWeight.w700,

                      height: 1.5,

                      fontSize: 15,

                    ),

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