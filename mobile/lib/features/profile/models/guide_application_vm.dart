import 'guide_profile_vm.dart';

class GuideApplicationVm {
  GuideApplicationVm({
    required this.profile,
    required this.documents,
    this.verificationRequest,
  });

  final GuideProfileVm profile;
  final GuideVerificationRequestVm? verificationRequest;
  final List<GuideVerificationDocumentVm> documents;

  factory GuideApplicationVm.fromJson(Map<String, dynamic> json) {
    final documents = json['documents'] as List<dynamic>? ?? const [];

    return GuideApplicationVm(
      profile: GuideProfileVm.fromJson(json),
      verificationRequest: json['verificationRequest'] is Map<String, dynamic>
          ? GuideVerificationRequestVm.fromJson(
              json['verificationRequest'] as Map<String, dynamic>,
            )
          : null,
      documents: documents
          .whereType<Map<String, dynamic>>()
          .map(GuideVerificationDocumentVm.fromJson)
          .toList(growable: false),
    );
  }
}

class GuideVerificationRequestVm {
  GuideVerificationRequestVm({
    required this.id,
    required this.guideProfileId,
    required this.status,
    this.comment,
    this.reviewComment,
    this.submittedAt,
    this.reviewedAt,
  });

  final String id;
  final String guideProfileId;
  final String status;
  final String? comment;
  final String? reviewComment;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;

  factory GuideVerificationRequestVm.fromJson(Map<String, dynamic> json) {
    return GuideVerificationRequestVm(
      id: json['id']?.toString() ?? '',
      guideProfileId: json['guideProfileId']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      comment: json['comment']?.toString(),
      reviewComment: json['reviewComment']?.toString(),
      submittedAt: DateTime.tryParse(json['submittedAt']?.toString() ?? ''),
      reviewedAt: DateTime.tryParse(json['reviewedAt']?.toString() ?? ''),
    );
  }

  bool get isPending {
    final normalized = status.trim().toUpperCase();
    return normalized == 'SUBMITTED' || normalized == 'UNDER_REVIEW';
  }
}

class GuideVerificationDocumentVm {
  GuideVerificationDocumentVm({
    required this.id,
    required this.verificationRequestId,
    required this.fileId,
    required this.documentType,
    this.createdAt,
  });

  final String id;
  final String verificationRequestId;
  final String fileId;
  final String documentType;
  final DateTime? createdAt;

  factory GuideVerificationDocumentVm.fromJson(Map<String, dynamic> json) {
    return GuideVerificationDocumentVm(
      id: json['id']?.toString() ?? '',
      verificationRequestId: json['verificationRequestId']?.toString() ?? '',
      fileId: json['fileId']?.toString() ?? '',
      documentType: json['documentType']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }
}
