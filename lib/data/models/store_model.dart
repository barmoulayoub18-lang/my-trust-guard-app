class StoreModel {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final double trustScore;
  final int complaintsCount;
  final bool isVerified;
  final DateTime createdAt;

  const StoreModel({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    required this.trustScore,
    required this.complaintsCount,
    required this.isVerified,
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

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    return value.toString().toLowerCase() == "true";
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
  // 🔄 FROM JSON (Supabase / Backend)
  // =====================================================
  factory StoreModel.fromJson(Map<String, dynamic> json) {
    return StoreModel(
      id: (json['id'] ?? "").toString(),
      name: (json['name'] ?? "Unknown Store").toString(),
      description: json['description']?.toString(),
      imageUrl: json['image_url']?.toString(),

      trustScore: _parseDouble(json['trust_score']),
      complaintsCount: _parseInt(json['complaints_count']),
      isVerified: _parseBool(json['is_verified']),

      createdAt: _parseDate(json['created_at']),
    );
  }

  // =====================================================
  // 🔄 TO JSON (App → Supabase)
  // =====================================================
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "description": description,
      "image_url": imageUrl,
      "trust_score": trustScore,
      "complaints_count": complaintsCount,
      "is_verified": isVerified,
      "created_at": createdAt.toIso8601String(),
    };
  }

  // =====================================================
  // ✏️ COPY WITH
  // =====================================================
  StoreModel copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    double? trustScore,
    int? complaintsCount,
    bool? isVerified,
    DateTime? createdAt,
  }) {
    return StoreModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      trustScore: trustScore ?? this.trustScore,
      complaintsCount: complaintsCount ?? this.complaintsCount,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // =====================================================
  // 🧾 HELPERS
  // =====================================================
  bool get isSafe => trustScore >= 80;
  bool get isMedium => trustScore >= 50 && trustScore < 80;
  bool get isDanger => trustScore < 50;

  String get label {
    if (trustScore >= 80) return "SAFE";
    if (trustScore >= 50) return "CAUTION";
    return "DANGEROUS";
  }

  // =====================================================
  // 🟰 EQUALITY
  // =====================================================
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is StoreModel &&
            other.id == id &&
            other.name == name &&
            other.trustScore == trustScore);
  }

  @override
  int get hashCode =>
      id.hashCode ^ name.hashCode ^ trustScore.hashCode;

  @override
  String toString() {
    return 'StoreModel(name: $name, score: $trustScore)';
  }
}