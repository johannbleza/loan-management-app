class Payment {
  final int? paymentId;
  final int loanTerm;
  final double interestRate;
  final String dueDate;
  final double principalBalance;
  final double monthlyPayment;
  final double interestPaid;
  final double capitalPayment;
  final double agentShare;
  final String? paymentDate;
  final String? paymentMode;
  final String? remarks;
  final String agentName;
  final int agentId;
  final int clientId;
  final String clientName;

  Payment({
    this.paymentId,
    required this.loanTerm,
    required this.interestRate,
    required this.dueDate,
    required this.principalBalance,
    required this.monthlyPayment,
    required this.interestPaid,
    required this.capitalPayment,
    required this.agentShare,
    this.paymentDate,
    this.paymentMode,
    this.remarks,
    required this.agentName,
    required this.agentId,
    required this.clientId,
    required this.clientName,
  });

  Map<String, dynamic> toMap() {
    return {
      'paymentId': paymentId,
      'loanTerm': loanTerm,
      'interestRate': interestRate,
      'dueDate': dueDate,
      'principalBalance': principalBalance,
      'monthlyPayment': monthlyPayment,
      'interestPaid': interestPaid,
      'capitalPayment': capitalPayment,
      'agentShare': agentShare,
      'paymentDate': paymentDate,
      'paymentMode': paymentMode,
      'remarks': remarks,
      'agentName': agentName,
      'agentId': agentId,
      'clientId': clientId,
      'clientName': clientName,
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      paymentId: map['paymentId'],
      loanTerm: map['loanTerm'],
      interestRate: map['interestRate'],
      dueDate: map['dueDate'],
      principalBalance: map['principalBalance'],
      monthlyPayment: map['monthlyPayment'],
      interestPaid: map['interestPaid'],
      capitalPayment: map['capitalPayment'],
      agentShare: map['agentShare'],
      paymentDate: map['paymentDate'],
      paymentMode: map['paymentMode'],
      remarks: map['remarks'],
      agentName: map['agentName'],
      agentId: map['agentId'],
      clientId: map['clientId'],
      clientName: map['clientName'],
    );
  }

  @override
  String toString() {
    return '{paymentId: $paymentId, loanTerm: $loanTerm, interestRate: $interestRate, dueDate: $dueDate, principalBalance: $principalBalance, monthlyPayment: $monthlyPayment, interestPaid: $interestPaid, capitalPayment: $capitalPayment, agentShare: $agentShare, paymentDate: $paymentDate, paymentMode: $paymentMode, remarks: $remarks, agentName: $agentName, agentId: $agentId, clientId: $clientId, clientName: $clientName}';
  }
}
