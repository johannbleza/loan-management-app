class Balancesheet {
  final int? balanceSheetId;
  final String date;
  final double balanceOUT;
  final double balanceIN;
  final double? balanceAmount;
  final String? remarks;
  final int? clientId;
  final int? paymentId;
  final int? partialPaymentId;

  Balancesheet({
    this.clientId,
    this.paymentId,
    this.partialPaymentId,
    this.balanceSheetId,
    this.balanceAmount,
    required this.date,
    required this.balanceOUT,
    required this.balanceIN,
    this.remarks,
  });

  Map<String, dynamic> toMap() {
    return {
      'balanceSheetId': balanceSheetId,
      'date': date,
      'balanceOUT': balanceOUT,
      'balanceIN': balanceIN,
      'balanceAmount': balanceAmount,
      'remarks': remarks,
      'clientId': clientId,
      'paymentId': paymentId,
      'partialPaymentId': partialPaymentId,
    };
  }

  factory Balancesheet.fromMap(Map<String, dynamic> map) {
    return Balancesheet(
      balanceSheetId: map['balanceSheetId'],
      date: map['date'],
      balanceOUT: map['balanceOUT'],
      balanceIN: map['balanceIN'],
      balanceAmount: map['balanceAmount'],
      remarks: map['remarks'],
      clientId: map['clientId'],
      paymentId: map['paymentId'],
      partialPaymentId: map['partialPaymentId'],
    );
  }
}
