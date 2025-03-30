class Payment {
  final int? paymentId;
  final int loanTerm;
  final String dueDate;
  final double monthlyPayment;
  final double interestPaid;
  final String? paymentDate;
  final String? paymentMode;
  final String? remarks;
  final int clientId;

  Payment({
    this.paymentId,
    required this.loanTerm,
    required this.dueDate,
    required this.monthlyPayment,
    required this.interestPaid,
    this.paymentDate,
    this.paymentMode,
    this.remarks,
    required this.clientId,
  });

  Map<String, dynamic> toMap() {
    return {
      'paymentId': paymentId,
      'loanTerm': loanTerm,
      'dueDate': dueDate,
      'monthlyPayment': monthlyPayment,
      'interestPaid': interestPaid,
      'paymentDate': paymentDate,
      'paymentMode': paymentMode,
      'remarks': remarks,
      'clientId': clientId,
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      paymentId: map['paymentId'],
      loanTerm: map['loanTerm'],
      dueDate: map['dueDate'],
      monthlyPayment: map['monthlyPayment'],
      interestPaid: map['interestPaid'],
      paymentDate: map['paymentDate'],
      paymentMode: map['paymentMode'],
      remarks: map['remarks'],
      clientId: map['clientId'],
    );
  }
}
