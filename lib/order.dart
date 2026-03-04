class Order {
  int? id;
  String cardHolder;
  String cardNumber;
  String validUntil;
  String cvv;
  String paymentMethod;
  String promoCode;
  double totalPrice;
  bool saveCard;
  String createdAt;

  Order({
    this.id,
    required this.cardHolder,
    required this.cardNumber,
    required this.validUntil,
    required this.cvv,
    required this.paymentMethod,
    this.promoCode = '',
    required this.totalPrice,
    this.saveCard = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cardHolder': cardHolder,
      'cardNumber': cardNumber,
      'validUntil': validUntil,
      'cvv': cvv,
      'paymentMethod': paymentMethod,
      'promoCode': promoCode,
      'totalPrice': totalPrice,
      'saveCard': saveCard ? 1 : 0,
      'createdAt': createdAt,
    };
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'],
      cardHolder: map['cardHolder'] ?? '',
      cardNumber: map['cardNumber'] ?? '',
      validUntil: map['validUntil'] ?? '',
      cvv: map['cvv'] ?? '',
      paymentMethod: map['paymentMethod'] ?? 'Credit',
      promoCode: map['promoCode'] ?? '',
      totalPrice: map['totalPrice'] ?? 0.0,
      saveCard: map['saveCard'] == 1,
      createdAt: map['createdAt'] ?? '',
    );
  }
}
