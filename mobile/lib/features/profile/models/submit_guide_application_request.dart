class SubmitGuideApplicationRequest {
  SubmitGuideApplicationRequest({
    required this.type,
    required this.identityDocumentFileId,
    required this.identityDocumentType,
    required this.professionalDocumentFileId,
    required this.professionalDocumentType,
    this.firstAidCertificateFileId,
    this.languageCertificateFileId,
    this.headline,
    this.about,
    this.experienceYears,
    this.comment,
    this.isExcursionGuideAvailable = true,
  });

  final String type;
  final String identityDocumentFileId;
  final String identityDocumentType;
  final String professionalDocumentFileId;
  final String professionalDocumentType;
  final String? firstAidCertificateFileId;
  final String? languageCertificateFileId;
  final String? headline;
  final String? about;
  final int? experienceYears;
  final String? comment;
  final bool isExcursionGuideAvailable;

  Map<String, dynamic> toJson() {
    return {
      'type': type.trim(),
      'identityDocumentFileId': identityDocumentFileId.trim(),
      'identityDocumentType': identityDocumentType.trim(),
      'professionalDocumentFileId': professionalDocumentFileId.trim(),
      'professionalDocumentType': professionalDocumentType.trim(),
      if ((firstAidCertificateFileId ?? '').trim().isNotEmpty)
        'firstAidCertificateFileId': firstAidCertificateFileId!.trim(),
      if ((languageCertificateFileId ?? '').trim().isNotEmpty)
        'languageCertificateFileId': languageCertificateFileId!.trim(),
      if ((headline ?? '').trim().isNotEmpty) 'headline': headline!.trim(),
      if ((about ?? '').trim().isNotEmpty) 'about': about!.trim(),
      if (experienceYears != null) 'experienceYears': experienceYears,
      if ((comment ?? '').trim().isNotEmpty) 'comment': comment!.trim(),
      'isExcursionGuideAvailable': isExcursionGuideAvailable,
    };
  }
}
