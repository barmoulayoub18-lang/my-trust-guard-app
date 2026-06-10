import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../presentation/widgets/custom_card.dart';

class TrustScreen extends StatefulWidget {
  final double score;
  final Map<String, dynamic> details;

  const TrustScreen({
    super.key,
    required this.score,
    required this.details,
  });

  @override
  State<TrustScreen> createState() => _TrustScreenState();
}

class _TrustScreenState extends State<TrustScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  double get score => widget.score;

  // =====================================================
  // 🎨 COLOR
  // =====================================================
  Color getColor() {
    if (score >= 80) return AppColors.trustHigh;
    if (score >= 50) return AppColors.trustMedium;
    return AppColors.trustLow;
  }

  String getLabel() {
    if (score >= 80) return "SAFE";
    if (score >= 50) return "CAUTION";
    return "DANGEROUS";
  }

  String getMessage() {
    if (score >= 80) {
      return "This store appears safe based on real data.";
    } else if (score >= 50) {
      return "Mixed signals detected. Verify before buying.";
    } else {
      return "High risk detected. Avoid this store.";
    }
  }

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _animation = Tween<double>(begin: 0, end: score).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // =====================================================
  // UI
  // =====================================================
  @override
  Widget build(BuildContext context) {
    final color = getColor();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Trust Score"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            const SizedBox(height: 10),

            // 🔥 HEADER
            CustomCard(
              gradient: AppColors.primaryGradient,
              child: const Row(
                children: [
                  Icon(Icons.verified_user, color: Colors.white),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "AI Trust Analysis Result",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // 🎯 SCORE (Animated Circle)
            AnimatedBuilder(
              animation: _animation,
              builder: (context, _) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 180,
                      height: 180,
                      child: CircularProgressIndicator(
                        value: _animation.value / 100,
                        strokeWidth: 10,
                        backgroundColor: Colors.grey.withOpacity(0.2),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "${_animation.value.toInt()}%",
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          getLabel(),
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 25),

            // 📊 PROGRESS BAR
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: score / 100,
                minHeight: 10,
                backgroundColor: Colors.grey.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),

            const SizedBox(height: 25),

            // 📋 DETAILS
            CustomCard(
              child: Column(
                children: [
                  buildRow("Reviews", widget.details["reviews"]),
                  buildRow("Activity", widget.details["activity"]),
                  buildRow("Source", widget.details["source"]),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 🧠 EXPLANATION
            if (widget.details["explanation"] != null)
              CustomCard(
                color: Colors.white.withOpacity(0.03),
                child: Text(
                  widget.details["explanation"].toString(),
                  style: const TextStyle(
                    color: Colors.grey,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: 20),

            // ⚠️ WARNING CARD
            CustomCard(
              color: color.withOpacity(0.08),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: color),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      getMessage(),
                      style: TextStyle(color: color),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // 🔹 ROW ITEM
  // =====================================================
  Widget buildRow(String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey)),
          Flexible(
            child: Text(
              value?.toString() ?? "-",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}