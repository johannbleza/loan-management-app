class Agent {
  final int? agentId;
  final String agentName;
  final String? contactNo;
  final String? email;

  Agent({this.contactNo, this.email, this.agentId, required this.agentName});

  Map<String, dynamic> toMap() {
    return {
      'agentId': agentId,
      'agentName': agentName,
      'contactNo': contactNo,
      'email': email,
    };
  }

  factory Agent.fromMap(Map<String, dynamic> map) {
    return Agent(
      agentId: map['agentId'],
      agentName: map['agentName'],
      contactNo: map['contactNo'],
      email: map['email'],
    );
  }

  @override
  String toString() {
    return '{agentId: $agentId, agentName: $agentName}';
  }
}
