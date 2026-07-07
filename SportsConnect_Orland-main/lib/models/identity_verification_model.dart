/// Model representing an identity verification record
class IdentityVerificationModel {
  final String? id;
  final String userId;
  final String documentType;
  final String frontImageUrl;
  final String backImageUrl;
  final String selfieUrl;
  final String status; // 'pending', 'verified', 'rejected'
  final DateTime? createdAt;
  final DateTime? updatedAt;

  IdentityVerificationModel({
    this.id,
    required this.userId,
    required this.documentType,
    required this.frontImageUrl,
    required this.backImageUrl,
    required this.selfieUrl,
    this.status = 'pending',
    this.createdAt,
    this.updatedAt,
  });

  factory IdentityVerificationModel.fromJson(Map<String, dynamic> json) {
    return IdentityVerificationModel(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      documentType: json['document_type'] as String,
      frontImageUrl: json['front_image_url'] as String,
      backImageUrl: json['back_image_url'] as String,
      selfieUrl: json['selfie_url'] as String,
      status: json['status'] as String? ?? 'pending',
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
      'user_id': userId,
      'document_type': documentType,
      'front_image_url': frontImageUrl,
      'back_image_url': backImageUrl,
      'selfie_url': selfieUrl,
      'status': status,
    };
  }

  bool get isVerified => status == 'verified';
  bool get isPending => status == 'pending';
  bool get isRejected => status == 'rejected';
}
