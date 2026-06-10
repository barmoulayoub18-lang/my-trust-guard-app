class WalletModel {
  final String id;
  final String userId;
  final double availableBalance;
  final double frozenBalance;
  final DateTime createdAt;

  const WalletModel({
    required this.id,
    required this.userId,
    required this.availableBalance,
    required this.frozenBalance,
    required this.createdAt,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      id: (json['id'] ?? '').toString(),
      userId: (json['user_id'] ?? json['userId'] ?? '').toString(),
      availableBalance: double.tryParse(json['available_balance']?.toString() ?? json['availableBalance']?.toString() ?? '0.0') ?? 0.0,
      frozenBalance: double.tryParse(json['frozen_balance']?.toString() ?? json['frozenBalance']?.toString() ?? '0.0') ?? 0.0,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'].toString()) 
          : (json['createdAt'] != null ? DateTime.parse(json['createdAt'].toString()) : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'available_balance': availableBalance,
      'frozen_balance': frozenBalance,
      'created_at': createdAt.toIso8601String(),
    };
  }

  WalletModel copyWith({
    String? id,
    String? userId,
    double? availableBalance,
    double? frozenBalance,
    DateTime? createdAt,
  }) {
    return WalletModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      availableBalance: availableBalance ?? this.availableBalance,
      frozenBalance: frozenBalance ?? this.frozenBalance,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  double get totalBalance => availableBalance + frozenBalance;
  bool get hasFunds => availableBalance > 0;

  bool canAfford(double amount) => availableBalance >= amount;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is WalletModel &&
            other.id == id &&
            other.userId == userId &&
            other.availableBalance == availableBalance &&
            other.frozenBalance == frozenBalance);
  }

  @override
  int get hashCode {
    return id.hashCode ^ userId.hashCode ^ availableBalance.hashCode ^ frozenBalance.hashCode;
  }
}