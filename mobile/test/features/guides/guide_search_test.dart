import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/features/guides/guide_search.dart';

void main() {
  test('guide search requires every query token to match localized fields', () {
    final fields = [
      'Elena Nomad',
      'City Historian',
      'Городской историк',
      'Russian',
      'Русский',
      'Kazakh',
      'Казахский',
    ];

    expect(guideSearchMatches('elena historian', fields), isTrue);
    expect(guideSearchMatches('городской русский', fields), isTrue);
    expect(guideSearchMatches('kazakh nomad', fields), isTrue);
    expect(guideSearchMatches('mountain nomad', fields), isFalse);
  });

  test('guide search normalizes punctuation case and common diacritics', () {
    final fields = ['Aria Silva', 'Nature Photographer', 'français'];

    expect(guideSearchMatches('ARIA nature', fields), isTrue);
    expect(guideSearchMatches('francais', fields), isTrue);
    expect(guideSearchMatches('photo-guide', fields), isFalse);
  });
}
