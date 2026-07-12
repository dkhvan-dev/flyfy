import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/features/profile/models/submit_guide_application_request.dart';

void main() {
  test('guide application enables excursion capability by default', () {
    final request = SubmitGuideApplicationRequest(
      type: 'INDEPENDENT',
      identityDocumentFileId: 'identity-file',
      identityDocumentType: 'PASSPORT',
      professionalDocumentFileId: 'professional-file',
      professionalDocumentType: 'GUIDE_LICENSE',
    );

    expect(request.toJson()['isExcursionGuideAvailable'], isTrue);
  });

  test('guide application preserves an explicit disabled capability', () {
    final request = SubmitGuideApplicationRequest(
      type: 'INDEPENDENT',
      identityDocumentFileId: 'identity-file',
      identityDocumentType: 'PASSPORT',
      professionalDocumentFileId: 'professional-file',
      professionalDocumentType: 'GUIDE_LICENSE',
      isExcursionGuideAvailable: false,
    );

    expect(request.toJson()['isExcursionGuideAvailable'], isFalse);
  });
}
