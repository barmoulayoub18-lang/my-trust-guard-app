import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/colors.dart';
import '../../presentation/widgets/custom_card.dart';

class TrustScreen extends StatefulWidget {
  final double score;
  final Map<String, dynamic> details;
  final String? storeId;

  const TrustScreen({
    super.key,
    required this.score,
    required this.details,
    this.storeId,
  });

  @override
  State<TrustScreen> createState() => _TrustScreenState();
}

class _TrustScreenState extends State<TrustScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  double _currentScore = 0;
  Map<String, dynamic> _currentDetails = {};
  String _sourceUrl = "-";
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    
    _currentScore = widget.score;
    _currentDetails = Map<String, dynamic>.from(widget.details);
    _sourceUrl = widget.storeId ?? widget.details["store_id"]?.toString() ?? "-";

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _animation = Tween<double>(begin: 0, end: _currentScore).animate(
      CurvedAnimation(parent: _controller, curve: Curves.fastOutSlowIn),
    );

    _controller.forward();
    _loadExactDataFromDatabase();
  }

  Future<void> _loadExactDataFromDatabase() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final client = Supabase.instance.client;
      final currentUser = client.auth.currentUser;
      
      dynamic query = client.from('analysis_results').select();

      if (_sourceUrl != "-" && _sourceUrl.isNotEmpty) {
        query = query.eq('store_id', _sourceUrl);
      } else if (currentUser != null) {
        query = query.eq('user_id', currentUser.id);
      }

      final List<dynamic> response = await query
          .order('created_at', ascending: false)
          .limit(1);

      if (response.isNotEmpty) {
        final data = response.first as Map<String, dynamic>;
        final double fetchedScore = (data['score'] as num?)?.toDouble() ?? 0.0;
        
        Map<String, dynamic> fetchedDetails = {};
        if (data['details'] != null && data['details'] is Map) {
          fetchedDetails = Map<String, dynamic>.from(data['details']);
        }

        if (mounted) {
          setState(() {
            _currentScore = fetchedScore;
            _currentDetails = fetchedDetails;
            if (data['store_id'] != null) {
              _sourceUrl = data['store_id'].toString();
            }
            _isLoading = false;

            _animation = Tween<double>(begin: 0, end: _currentScore).animate(
              CurvedAnimation(parent: _controller, curve: Curves.fastOutSlowIn),
            );
          });
          _controller.reset();
          _controller.forward();
        }
      } else {
        if (mounted) {
          setState(() {
            if (_currentScore > 0) {
              _isLoading = false;
            } else {
              _isLoading = false;
              _errorMessage = "No analysis records found in your account.";
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (_currentScore == 0) {
            _errorMessage = "Connection error. Please try again.";
          }
        });
      }
    }
  }

  Color getColor() {
    if (_currentScore >= 80) return AppColors.trustHigh;
    if (_currentScore >= 50) return AppColors.trustMedium;
    return AppColors.trustLow;
  }

  String getLabel() {
    if (_currentScore >= 80) return "SAFE";
    if (_currentScore >= 50) return "CAUTION";
    return "DANGEROUS";
  }

  String getMessage() {
    if (_currentScore >= 80) {
      return "This store appears safe based on real data.";
    } else if (_currentScore >= 50) {
      return "Mixed signals detected. Verify before buying.";
    } else {
      return "High risk detected. Avoid this store.";
    }
  }

  dynamic _extractValue(List<String> keys) {
    for (var key in keys) {
      if (_currentDetails.containsKey(key) && _currentDetails[key] != null) {
        return _currentDetails[key];
      }
      final lowerKey = key.toLowerCase();
      if (_currentDetails.containsKey(lowerKey) && _currentDetails[lowerKey] != null) {
        return _currentDetails[lowerKey];
      }
      final upperKey = key.toUpperCase();
      if (_currentDetails.containsKey(upperKey) && _currentDetails[upperKey] != null) {
        return _currentDetails[upperKey];
      }
    }
    return null;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = getColor();

    final reviewsValue = _extractValue(["reviews", "Reviews"]);
    final activityValue = _extractValue(["activity", "Activity"]);
    final explanationValue = _extractValue(["explanation", "Explanation", "reason", "comment"]);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Trust Score",
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
        actions: [
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.textPrimary),
                    ),
                  )
                : const Icon(Icons.refresh_rounded),
            onPressed: _loadExactDataFromDatabase,
          ),
        ],
      ),
      body: _isLoading && _currentScore == 0
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
          : _errorMessage != null && _currentScore == 0
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 48,
                          color: AppColors.textSecondary.withOpacity(0.4),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
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
                          child: const Row(
                            children: [
                              Icon(Icons.verified_user, color: Colors.white, size: 20),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "AI Trust Analysis Result",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      AnimatedBuilder(
                        animation: _animation,
                        builder: (context, child) {
                          return TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 600),
                            tween: Tween<double>(begin: 0.0, end: 1.0),
                            builder: (context, scale, child) {
                              return Transform.scale(
                                scale: 0.9 + (0.1 * scale),
                                child: Opacity(
                                  opacity: scale,
                                  child: child,
                                ),
                              );
                            },
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 200,
                                  height: 200,
                                  child: CircularProgressIndicator(
                                    value: _animation.value / 100,
                                    strokeWidth: 12,
                                    backgroundColor: AppColors.border,
                                    valueColor: AlwaysStoppedAnimation<Color>(color),
                                  ),
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "${_animation.value.toInt()}%",
                                      style: TextStyle(
                                        fontSize: 40,
                                        fontWeight: FontWeight.w900,
                                        color: color,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        getLabel(),
                                        style: TextStyle(
                                          color: color,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 32),
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 500),
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: child,
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: _currentScore / 100,
                            minHeight: 8,
                            backgroundColor: AppColors.border,
                            valueColor: AlwaysStoppedAnimation(color),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 600),
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 15 * (1.0 - value)),
                              child: child,
                            ),
                          );
                        },
                        child: CustomCard(
                          child: Column(
                            children: [
                              buildRow("Reviews", reviewsValue),
                              const Divider(color: AppColors.border, height: 1),
                              buildRow("Activity", activityValue),
                              const Divider(color: AppColors.border, height: 1),
                              buildRow("Source", _sourceUrl),
                            ],
                          ),
                        ),
                      ),
                      if (explanationValue != null) ...[
                        const SizedBox(height: 16),
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 700),
                          tween: Tween<double>(begin: 0.0, end: 1.0),
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 15 * (1.0 - value)),
                                child: child,
                              ),
                            );
                          },
                          child: CustomCard(
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                explanationValue.toString(),
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 800),
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 15 * (1.0 - value)),
                              child: child,
                            ),
                          );
                        },
                        child: CustomCard(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline_rounded, color: color, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    getMessage(),
                                    style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  Widget buildRow(String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value?.toString() ?? "-",
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}