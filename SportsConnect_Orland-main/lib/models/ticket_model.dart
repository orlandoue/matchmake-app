/// Model representing a user's ticket balance
class TicketModel {
  final String id;
  final String userId;
  final int singlesQuantity;
  final int doublesQuantity;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TicketModel({
    required this.id,
    required this.userId,
    required this.singlesQuantity,
    required this.doublesQuantity,
    this.createdAt,
    this.updatedAt,
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    return TicketModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      singlesQuantity: json['singles_quantity'] as int? ?? 0,
      doublesQuantity: json['doubles_quantity'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'singles_quantity': singlesQuantity,
      'doubles_quantity': doublesQuantity,
    };
  }
}

/// Model representing a ticket transaction (purchase, usage, refund)
class TicketTransactionModel {
  final String id;
  final String userId;
  final String type; // 'purchase', 'usage', 'refund'
  final int quantity;
  final String? ticketType; // 'singles' or 'doubles'
  final String? matchId;
  final String? paymentId;
  final String? paymentStatus;
  final double? amount;
  final String? currency;
  final String? mercadopagoPaymentId;
  final DateTime? createdAt;

  TicketTransactionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.quantity,
    this.ticketType,
    this.matchId,
    this.paymentId,
    this.paymentStatus,
    this.amount,
    this.currency,
    this.mercadopagoPaymentId,
    this.createdAt,
  });

  factory TicketTransactionModel.fromJson(Map<String, dynamic> json) {
    return TicketTransactionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: json['type'] as String,
      quantity: json['quantity'] as int,
      ticketType: json['ticket_type'] as String?,
      matchId: json['match_id'] as String?,
      paymentId: json['payment_id'] as String?,
      paymentStatus: json['payment_status'] as String?,
      amount:
          json['amount'] != null ? (json['amount'] as num).toDouble() : null,
      currency: json['currency'] as String?,
      mercadopagoPaymentId: json['mercadopago_payment_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'type': type,
      'quantity': quantity,
      if (ticketType != null) 'ticket_type': ticketType,
      if (matchId != null) 'match_id': matchId,
      if (paymentId != null) 'payment_id': paymentId,
      if (paymentStatus != null) 'payment_status': paymentStatus,
      if (amount != null) 'amount': amount,
      if (currency != null) 'currency': currency,
      if (mercadopagoPaymentId != null)
        'mercadopago_payment_id': mercadopagoPaymentId,
    };
  }
}
