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
    var details = json['scan_details'] ?? json['details'] ?? json['data']?['details'] ?? json['data'];
    
    int parsedScore = 0;
    var scoreRaw = json['risk_score'] ?? json['riskScore'] ?? json['data']?['risk_score'];
    if (scoreRaw == null && details is Map) {
      scoreRaw = details['risk_score'] ?? details['riskScore'] ?? details['score'];
    }
    if (scoreRaw != null) {
      parsedScore = int.tryParse(scoreRaw.toString()) ?? 0;
    }

    bool phishingStatus = false;
    var phishingRaw = json['is_phishing'] ?? json['isPhishing'] ?? json['data']?['is_phishing'];
    if (phishingRaw == null && details is Map) {
      phishingRaw = details['is_phishing'] ?? details['isPhishing'] ?? (details['risk'] == 'high');
    }
    if (phishingRaw != null) {
      phishingStatus = phishingRaw == true;
    }

    return LinkScanModel(
      id: json['id']?.toString(),
      originalUrl: (json['original_url'] ?? json['originalUrl'] ?? json['data']?['original_url'] ?? '').toString(),
      finalUrl: (json['final_url'] ?? json['finalUrl'] ?? json['data']?['final_url'] ?? '').toString(),
      riskScore: parsedScore,
      isPhishing: phishingStatus,
      scanDetails: details is Map<String, dynamic> 
          ? Map<String, dynamic>.from(details) 
          : (json['data'] is Map<String, dynamic> ? Map<String, dynamic>.from(json['data']) : {}),
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

  String get siteSummary {
    var summary = scanDetails['site_summary'] ?? scanDetails['siteSummary'] ?? scanDetails['reviews'] ?? scanDetails['explanation'];
    if (summary != null) {
      return summary.toString();
    }
    return 'تحليل محتوى الموقع غير متوفر حالياً.';
  }

  String get verifiableReason {
    var reason = scanDetails['verifiable_reason'] ?? scanDetails['verifiableReason'] ?? scanDetails['explanation'];
    if (reason != null) {
      return reason.toString();
    }
    return 'التحليل الهيكلي للنطاق قيد المعالجة ولم يسترجع أي بيانات تفصيلية.';
  }

  List<String> get detectedFlags {
    var flags = scanDetails['detected_flags'] ?? scanDetails['detectedFlags'] ?? scanDetails['red_flags'];
    if (flags is List) {
      return List<String>.from(flags.map((e) => e.toString()));
    }
    return [];
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