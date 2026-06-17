class EscrowDemoAccountModel {
  final String id;
  final String demoIdentifier;
  final String displayName;
  final String simulatedRole;

  EscrowDemoAccountModel({
    required this.id,
    required this.demoIdentifier,
    required this.displayName,
    required this.simulatedRole,
  });

  factory EscrowDemoAccountModel.fromJson(Map<String, dynamic> json) {
    return EscrowDemoAccountModel(
      id: json['id']?.toString() ?? '',
      demoIdentifier: json['demo_identifier']?.toString() ?? '',
      displayName: json['display_name']?.toString() ?? '',
      simulatedRole: json['simulated_role']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'demo_identifier': demoIdentifier,
      'display_name': displayName,
      'simulated_role': simulatedRole,
    };
  }
}