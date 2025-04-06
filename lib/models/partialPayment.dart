class Partialpayment {
  final int? partialPaymentId;
  final String dueDate;
  final double interestRate;
  final double? capitalPayment;
  final double? interestPaid;
  final String? paymentDate;
  final String? paymentMode;
  final String? remarks;
  final double agentShare;
  final int agentId;
  final String agentName;
  final int clientId;
  final String clientName;
  final int paymentId;

  Partialpayment({
    this.partialPaymentId,
    required this.dueDate,
    required this.interestRate,
    this.capitalPayment,
    this.interestPaid,
    this.paymentDate,
    this.paymentMode,
    this.remarks,
    required this.agentShare,
    required this.agentId,
    required this.agentName,
    required this.clientId,
    required this.clientName,
    required this.paymentId,
  });

  Map<String, dynamic> toMap() {
    return {
      'partialPaymentId': partialPaymentId,
      'dueDate': dueDate,
      'interestRate': interestRate,
      'capitalPayment': capitalPayment,
      'interestPaid': interestPaid,
      'paymentDate': paymentDate,
      'paymentMode': paymentMode,
      'remarks': remarks,
      'agentShare': agentShare,
      'agentId': agentId,
      'agentName': agentName,
      'clientId': clientId,
      'clientName': clientName,
      'paymentId': paymentId,
    };
  }

  factory Partialpayment.fromMap(Map<String, dynamic> map) {
    return Partialpayment(
      partialPaymentId: map['partialPaymentId'],
      dueDate: map['dueDate'],
      interestRate: map['interestRate'],
      capitalPayment: map['capitalPayment'],
      interestPaid: map['interestPaid'],
      paymentDate: map['paymentDate'],
      paymentMode: map['paymentMode'],
      remarks: map['remarks'],
      agentShare: map['agentShare'],
      agentId: map['agentId'],
      agentName: map['agentName'],
      clientId: map['clientId'],
      clientName: map['clientName'],
      paymentId: map['paymentId'],
    );
  }
}
