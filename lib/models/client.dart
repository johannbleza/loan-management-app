class Client {
  final int? clientId;
  final String clientName;
  final String loanDate;
  final double loanAmount;
  final int loanTerm;
  final double interestRate;
  final int agentId;
  final double agentShare;

  Client({
    this.clientId,
    required this.clientName,
    required this.loanDate,
    required this.loanAmount,
    required this.loanTerm,
    required this.interestRate,
    required this.agentId,
    required this.agentShare,
  });

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'clientName': clientName,
      'loanAmount': loanAmount,
      'loanDate': loanDate,
      'loanTerm': loanTerm,
      'interestRate': interestRate,
      'agentId': agentId,
      'agentShare': agentShare,
    };
  }

  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      clientId: map['clientId'],
      clientName: map['clientName'],
      loanDate: map['loanDate'],
      loanAmount: map['loanAmount'].toDouble(),
      loanTerm: map['loanTerm'],
      interestRate: map['interestRate'].toDouble(),
      agentId: map['agentId'],
      agentShare: map['agentShare'].toDouble(),
    );
  }

  @override
  String toString() {
    return '{clientId: $clientId, clientName: $clientName, loanDate: $loanDate, loanAmount: $loanAmount, loanTerm: $loanTerm, interestRate: $interestRate, agentId: $agentId, agentShare: $agentShare}';
  }
}
