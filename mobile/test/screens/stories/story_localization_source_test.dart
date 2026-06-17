import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Russian story editor localization covers critical content engine UI',
    () async {
      final ruArb =
          jsonDecode(await File('lib/l10n/app_ru.arb').readAsString())
              as Map<String, dynamic>;

      expect(ruArb['storyEditorTitle'], 'Редактор поста');
      expect(ruArb['storyEditorPublishReadiness'], 'Готовность к публикации');
      expect(ruArb['storyEditorAutosaveSaving'], 'Сохранение');
      expect(
        ruArb['storyEditorRecoveryTitle'],
        'Восстановить несохраненный черновик?',
      );
      expect(ruArb['storyEditorMediaQueued'], 'В очереди на загрузку');
      expect(
        ruArb['storyEditorMediaErrorRetryUpload'],
        'Повторите загрузку медиа.',
      );
      expect(
        ruArb['storyEditorMediaErrorInterrupted'],
        'Загрузка была прервана. Повторите, чтобы продолжить.',
      );
      expect(
        ruArb['storyEditorMediaErrorMissingSource'],
        'Локальный источник медиа недоступен. Удалите и добавьте это медиа снова.',
      );
      expect(
        ruArb['storyEditorValidationMediaPending'],
        'Дождитесь завершения загрузки медиа.',
      );
      expect(ruArb['myStoriesDraftsTab'], 'Черновики');
      expect(ruArb['myStoriesArchivedTab'], 'Архив');
    },
  );

  test(
    'story media errors are not rendered from hardcoded English messages',
    () async {
      final controllerSource = await File(
        'lib/features/stories/editor/presentation/story_editor_controller.dart',
      ).readAsString();
      final mediaBlockSource = await File(
        'lib/features/stories/editor/presentation/widgets/story_media_block.dart',
      ).readAsString();

      expect(controllerSource, isNot(contains('Retry upload.')));
      expect(controllerSource, isNot(contains('Upload was interrupted')));
      expect(
        controllerSource,
        isNot(contains('Local media source is unavailable')),
      );
      expect(mediaBlockSource, isNot(contains('queueItem!.errorMessage')));
      expect(mediaBlockSource, contains('storyEditorMediaErrorRetryUpload'));
    },
  );
}
