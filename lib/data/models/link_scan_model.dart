class LinkScanModel {
  final String? id;
  final String originalUrl;
  final String finalUrl;
  final int riskScore;
  final bool isPhishing;
  final Map<String, dynamic> scanDetails;
  final DateTime createdAt;

  const LinkScanModel({
    this.id,
    required this.originalUrl,
    required this.finalUrl,
    required this.riskScore,
    required this.isPhishing,
    required this.scanDetails,
    required this.createdAt,
  });

  factory LinkScanModel.fromJson(Map<String, dynamic> json) {
    var details = json['scan_details'] ?? json['details'];
    return LinkScanModel(
      id: json['id']?.toString(),
      originalUrl: (json['original_url'] ?? json['originalUrl'] ?? '').toString(),
      finalUrl: (json['final_url'] ?? json['finalUrl'] ?? '').toString(),
      riskScore: int.tryParse(json['risk_score']?.toString() ?? json['riskScore']?.toString() ?? '0') ?? 0,
      isPhishing: json['is_phishing'] == true || json['isPhishing'] == true,
      scanDetails: details is Map<String, dynamic> 
          ? Map<String, dynamic>.from(details) 
          : {},
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'].toString()) 
          : (json['createdAt'] != null ? DateTime.parse(json['createdAt'].toString()) : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'original_url': originalUrl,
      'final_url': finalUrl,
      'risk_score': riskScore,
      'is_phishing': isPhishing,
      'scan_details': scanDetails,
      'created_at': createdAt.toIso8601String(),
    };
  }

  LinkScanModel copyWith({
    String? id,
    String? originalUrl,
    String? finalUrl,
    int? riskScore,
    bool? isPhishing,
    Map<String, dynamic>? scanDetails,
    DateTime? createdAt,
  }) {
    return LinkScanModel(
      id: id ?? this.id,
      originalUrl: originalUrl ?? this.originalUrl,
      finalUrl: finalUrl ?? this.finalUrl,
      riskScore: riskScore ?? this.riskScore,
      isPhishing: isPhishing ?? this.isPhishing,
      scanDetails: scanDetails ?? this.scanDetails,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isSafe => riskScore < 50;
  bool get isDanger => riskScore >= 50;

  String get label {
    if (riskScore >= 75) return "DANGEROUS";
    if (riskScore >= 50) return "CAUTION";
    return "SAFE";
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is LinkScanModel &&
            other.id == id &&
            other.originalUrl == originalUrl &&
            other.riskScore == riskScore &&
            other.isPhishing == isPhishing);
  }

  @override
  int get hashCode {
    return id.hashCode ^ originalUrl.hashCode ^ riskScore.hashCode ^ isPhishing.hashCode;
  }
}