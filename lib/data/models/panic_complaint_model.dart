class PanicComplaintModel {
  final String? id;
  final String userId;
  final String scamType;
  final String country;
  final String generatedReport;
  final String status;
  final DateTime createdAt;

  const PanicComplaintModel({
    this.id,
    required this.userId,
    required this.scamType,
    required this.country,
    required this.generatedReport,
    required this.status,
    required this.createdAt,
  });

  factory PanicComplaintModel.fromJson(Map<String, dynamic> json) {
    return PanicComplaintModel(
      id: json['id']?.toString(),
      userId: (json['user_id'] ?? json['userId'] ?? '').toString(),
      scamType: (json['scam_type'] ?? json['scamType'] ?? '').toString(),
      country: (json['country'] ?? '').toString(),
      generatedReport: (json['generated_report'] ?? json['generatedReport'] ?? '').toString(),
      status: (json['status'] ?? 'generated').toString(),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'].toString()) 
          : (json['createdAt'] != null ? DateTime.parse(json['createdAt'].toString()) : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'scam_type': scamType,
      'country': country,
      'generated_report': generatedReport,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  PanicComplaintModel copyWith({
    String? id,
    String? userId,
    String? scamType,
    String? country,
    String? generatedReport,
    String? status,
    DateTime? createdAt,
  }) {
    return PanicComplaintModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      scamType: scamType ?? this.scamType,
      country: country ?? this.country,
      generatedReport: generatedReport ?? this.generatedReport,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isPending => status == 'pending';
  bool get isResolved => status == 'resolved';

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PanicComplaintModel &&
            other.id == id &&
            other.userId == userId &&
            other.scamType == scamType &&
            other.status == status);
  }

  @override
  int get hashCode {
    return id.hashCode ^ userId.hashCode ^ scamType.hashCode ^ status.hashCode;
  }
}