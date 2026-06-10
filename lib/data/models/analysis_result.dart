class AnalysisResult {
  final String? id;
  final String? userId;
  final String storeId;
  final double score;
  final String risk;
  final String reviews;
  final String activity;
  final String trustSignals;
  final List<String> redFlags;
  final String explanation;
  final DateTime createdAt;

  const AnalysisResult({
    this.id,
    this.userId,
    required this.storeId,
    required this.score,
    required this.risk,
    required this.reviews,
    required this.activity,
    required this.trustSignals,
    required this.redFlags,
    required this.explanation,
    required this.createdAt,
  });

  // =====================================================
  // 🧠 SAFE PARSERS
  // =====================================================
  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static List<String> _parseList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return DateTime.now();
    }
  }

  // =====================================================
  // 🔄 FROM JSON (Backend / Supabase)
  // =====================================================
  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      id: json['id']?.toString(),
      userId: json['user_id']?.toString(),
      storeId: (json['store_id'] ?? json['store'] ?? "").toString(),

      score: _parseDouble(json['score']),
      risk: (json['risk'] ?? "unknown").toString(),

      reviews: (json['reviews'] ?? "unknown").toString(),
      activity: (json['activity'] ?? "unknown").toString(),
      trustSignals: (json['trust_signals'] ?? "unknown").toString(),

      redFlags: _parseList(json['red_flags']),

      explanation: (json['explanation'] ?? "").toString(),

      createdAt: _parseDate(json['created_at']),
    );
  }

  // =====================================================
  // 🔄 TO JSON (App → Supabase)
  // =====================================================
  Map<String, dynamic> toJson() {
    return {
      if (id != null) "id": id,
      if (userId != null) "user_id": userId,
      "store_id": storeId,
      "score": score,
      "risk": risk,
      "reviews": reviews,
      "activity": activity,
      "trust_signals": trustSignals,
      "red_flags": redFlags,
      "explanation": explanation,
      "created_at": createdAt.toIso8601String(),
    };
  }

  // =====================================================
  // ✏️ COPY WITH
  // =====================================================
  AnalysisResult copyWith({
    String? id,
    String? userId,
    String? storeId,
    double? score,
    String? risk,
    String? reviews,
    String? activity,
    String? trustSignals,
    List<String>? redFlags,
    String? explanation,
    DateTime? createdAt,
  }) {
    return AnalysisResult(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      storeId: storeId ?? this.storeId,
      score: score ?? this.score,
      risk: risk ?? this.risk,
      reviews: reviews ?? this.reviews,
      activity: activity ?? this.activity,
      trustSignals: trustSignals ?? this.trustSignals,
      redFlags: redFlags ?? this.redFlags,
      explanation: explanation ?? this.explanation,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // =====================================================
  // 🧾 HELPERS
  // =====================================================
  bool get isSafe => score >= 80;
  bool get isMedium => score >= 50 && score < 80;
  bool get isDanger => score < 50;

  String get label {
    if (score >= 80) return "SAFE";
    if (score >= 50) return "CAUTION";
    return "DANGEROUS";
  }

  // =====================================================
  // 🟰 EQUALITY (مهم للـ state management)
  // =====================================================
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is AnalysisResult &&
            other.id == id &&
            other.storeId == storeId &&
            other.score == score &&
            other.risk == risk);
  }

  @override
  int get hashCode =>
      id.hashCode ^ storeId.hashCode ^ score.hashCode ^ risk.hashCode;

  @override
  String toString() {
    return 'AnalysisResult(storeId: $storeId, score: $score, risk: $risk)';
  }
}