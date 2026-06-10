class UserModel {
  final String id;
  final String email;
  final String role;
  final double trustScore;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.role,
    required this.trustScore,
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
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] ?? "").toString(),
      email: (json['email'] ?? "").toString(),
      role: (json['role'] ?? "user").toString(),
      trustScore: _parseDouble(json['trust_score']),
      createdAt: _parseDate(json['created_at']),
    );
  }

  // =====================================================
  // 🔄 TO JSON (App → Supabase)
  // =====================================================
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "email": email,
      "role": role,
      "trust_score": trustScore,
      "created_at": createdAt.toIso8601String(),
    };
  }

  // =====================================================
  // ✏️ COPY WITH
  // =====================================================
  UserModel copyWith({
    String? id,
    String? email,
    String? role,
    double? trustScore,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      trustScore: trustScore ?? this.trustScore,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // =====================================================
  // 🧾 HELPERS
  // =====================================================
  bool get isAdmin => role.toLowerCase() == "admin";
  bool get isUser => role.toLowerCase() == "user";

  bool get isTrusted => trustScore >= 80;
  bool get isMedium => trustScore >= 50 && trustScore < 80;
  bool get isLowTrust => trustScore < 50;

  String get trustLabel {
    if (trustScore >= 80) return "HIGH TRUST";
    if (trustScore >= 50) return "MEDIUM TRUST";
    return "LOW TRUST";
  }

  // =====================================================
  // 🟰 EQUALITY
  // =====================================================
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is UserModel &&
            other.id == id &&
            other.email == email &&
            other.trustScore == trustScore);
  }

  @override
  int get hashCode => id.hashCode ^ email.hashCode ^ trustScore.hashCode;

  @override
  String toString() {
    return 'UserModel(email: $email, trust: $trustScore)';
  }
}
