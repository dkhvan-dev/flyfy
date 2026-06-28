import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/core/network/chat_api.dart';
import 'package:inflap/core/network/chat_ws_service.dart';
import 'package:inflap/core/network/file_api.dart';
import 'package:inflap/core/ui/app_design_system.dart';
import 'package:go_router/go_router.dart';
import 'package:inflap/features/chat/models/conversation_vm.dart';
import 'package:inflap/features/help_center/data/help_center_api.dart';
import 'package:inflap/features/help_center/presentation/support_tickets_screen.dart';
import 'package:inflap/l10n/generated/app_localizations.dart';
import 'package:inflap/providers/chat_provider.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets(
    'SupportTicketsScreen opens the unified support chat instead of ticket list',
    (tester) async {
      final api = _FakeHelpCenterApi(
        detail: SupportTicketDetailVm(
          ticket: _ticket(id: 'ticket-single-chat', status: 'waiting_support'),
          events: [
            SupportTicketEventVm(
              ticketId: 'ticket-single-chat',
              actorId: 'user-123',
              actorType: 'user',
              eventType: 'user_replied',
              payload: const {'message_preview': 'Нужна помощь.'},
              createdAt: DateTime.utc(2026, 6, 20, 12),
            ),
          ],
        ),
      );

      await tester.pumpWidget(_testApp(SupportTicketsScreen(api: api)));
      await tester.pumpAndSettle();

      expect(find.text('Support chat'), findsOneWidget);
      expect(find.text('Нужна помощь.'), findsOneWidget);
      expect(api.getConversationCalls, 1);
      expect(api.listCalls, 0);
      expect(api.createTicketCalls, 0);
      expect(
        find.byKey(const ValueKey('support-ticket-card-ticket-user-123')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('support-create-ticket')), findsNothing);
      expect(find.text('ticket-single-chat'), findsNothing);
      expect(find.text('technical'), findsNothing);
      expect(find.text('help_center'), findsNothing);
      expect(find.text('normal'), findsNothing);
    },
  );

  testWidgets('SupportTicketDetailScreen hides technical support ticket id', (
    tester,
  ) async {
    const technicalTicketId = 'support-6c91f13b-8e3f-4a10-9d11-54c17fc7a3d1';
    final api = _FakeHelpCenterApi(
      tickets: [_ticket(id: technicalTicketId, status: 'waiting_support')],
      detail: SupportTicketDetailVm(
        ticket: _ticket(id: technicalTicketId, status: 'waiting_support'),
        events: [
          SupportTicketEventVm(
            ticketId: technicalTicketId,
            actorId: 'system',
            actorType: 'system',
            eventType: 'ticket_created',
            payload: const {},
            createdAt: DateTime.utc(2026, 6, 20, 12),
          ),
        ],
      ),
    );

    await tester.pumpWidget(_testApp(SupportTicketsScreen(api: api)));
    await tester.pumpAndSettle();

    expect(find.text(technicalTicketId), findsNothing);
    expect(find.text('Support chat'), findsOneWidget);

    await tester.pumpWidget(
      _testApp(
        SupportTicketDetailScreen(ticketId: technicalTicketId, api: api),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SupportTicketDetailScreen), findsOneWidget);
    expect(find.text(technicalTicketId), findsNothing);
    expect(find.text('Support chat'), findsOneWidget);
  });

  testWidgets('SupportTicketDetailScreen shows expected first response time', (
    tester,
  ) async {
    final api = _FakeHelpCenterApi(
      detail: SupportTicketDetailVm(
        ticket: _ticket(
          id: 'ticket-response-time',
          status: 'waiting_support',
          priority: 'normal',
          createdAt: DateTime.utc(2026, 6, 20, 11, 55),
        ),
        events: [
          SupportTicketEventVm(
            ticketId: 'ticket-response-time',
            actorId: 'user-123',
            actorType: 'user',
            eventType: 'user_replied',
            payload: const {'message_preview': 'Нужна помощь.'},
            createdAt: DateTime.utc(2026, 6, 20, 11, 55),
          ),
        ],
      ),
    );

    await tester.pumpWidget(_testApp(SupportTicketsScreen(api: api)));
    await tester.pumpAndSettle();

    expect(find.text('We usually answer within 30 min'), findsOneWidget);
  });

  testWidgets(
    'Support route keeps one support chat without returning to ticket list',
    (tester) async {
      final api = _FakeHelpCenterApi(
        detail: SupportTicketDetailVm(
          ticket: _ticket(id: 'ticket-single-chat', status: 'waiting_support'),
          events: [
            SupportTicketEventVm(
              ticketId: 'ticket-single-chat',
              actorId: 'user-123',
              actorType: 'user',
              eventType: 'user_replied',
              payload: const {'message_preview': 'Нужна помощь.'},
              createdAt: DateTime.utc(2026, 6, 20, 12),
            ),
          ],
        ),
      );
      final router = GoRouter(
        initialLocation: '/help/support',
        routes: [
          GoRoute(
            path: '/help/support',
            builder: (_, _) => SupportTicketsScreen(api: api),
          ),
          GoRoute(
            path: '/help/support/:ticketId',
            builder: (_, state) => SupportTicketDetailScreen(
              ticketId: state.pathParameters['ticketId']!,
              api: api,
            ),
          ),
        ],
      );

      await tester.pumpWidget(_routerTestApp(router));
      await tester.pumpAndSettle();
      expect(api.getConversationCalls, 1);
      expect(api.listCalls, 0);
      expect(find.byType(SupportTicketDetailScreen), findsOneWidget);
      expect(find.text('Нужна помощь.'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('support-ticket-card-ticket-user-123')),
        findsNothing,
      );

      router.go('/help/support/ticket-single-chat');
      await tester.pumpAndSettle();

      expect(find.byType(SupportTicketDetailScreen), findsOneWidget);
      expect(api.listCalls, 0);
    },
  );

  testWidgets('SupportTicketDetailScreen sends user reply', (tester) async {
    final api = _FakeHelpCenterApi(
      detail: SupportTicketDetailVm(
        ticket: _ticket(
          id: 'ticket-user-123',
          status: 'waiting_user',
          conversationId: 'conversation-123',
        ),
        events: [
          SupportTicketEventVm(
            ticketId: 'ticket-user-123',
            actorId: 'agent-1',
            actorType: 'support_agent',
            eventType: 'agent_replied',
            payload: const {
              'message_preview': 'Please send the receipt.',
              'actor_display_name': 'Aruzhan Ops',
            },
            createdAt: DateTime.utc(2026, 6, 20, 11, 30),
          ),
        ],
      ),
      replyResult: _ticket(
        id: 'ticket-user-123',
        status: 'waiting_support',
        conversationId: 'conversation-123',
      ),
    );

    await tester.pumpWidget(
      _testApp(
        SupportTicketDetailScreen(ticketId: 'ticket-user-123', api: api),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Please send the receipt.'), findsOneWidget);
    expect(find.text('Aruzhan Ops'), findsOneWidget);
    expect(find.text('support_agent'), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey('support-ticket-reply-field')),
      'Here is the receipt.',
    );
    await tester.tap(find.byKey(const ValueKey('support-ticket-send-reply')));
    await tester.pumpAndSettle();

    expect(api.lastReplyTicketId, 'ticket-user-123');
    expect(api.lastReplyMessage, 'Here is the receipt.');
    expect(find.text('You'), findsOneWidget);
    expect(find.text('Waiting for support'), findsOneWidget);

    await tester.pump(const Duration(seconds: 9));
    await tester.pumpAndSettle();

    expect(find.text('Here is the receipt.'), findsOneWidget);
  });

  testWidgets(
    'SupportTicketDetailScreen refreshes open chat for agent replies',
    (tester) async {
      final initialEvent = SupportTicketEventVm(
        ticketId: 'ticket-user-123',
        actorId: 'user-123',
        actorType: 'user',
        eventType: 'user_replied',
        payload: const {
          'message_preview': 'Can you check my booking?',
          'actor_nickname': '@nomad',
        },
        createdAt: DateTime.utc(2026, 6, 20, 11, 30),
      );
      final api = _FakeHelpCenterApi(
        detail: SupportTicketDetailVm(
          ticket: _ticket(id: 'ticket-user-123', status: 'waiting_support'),
          events: [initialEvent],
        ),
      );

      await tester.pumpWidget(
        _testApp(
          SupportTicketDetailScreen(ticketId: 'ticket-user-123', api: api),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Can you check my booking?'), findsOneWidget);
      expect(find.text('We checked it from admin.'), findsNothing);

      api.detail = SupportTicketDetailVm(
        ticket: _ticket(id: 'ticket-user-123', status: 'waiting_user'),
        events: [
          initialEvent,
          SupportTicketEventVm(
            ticketId: 'ticket-user-123',
            actorId: 'agent-1',
            actorType: 'support_agent',
            eventType: 'agent_replied',
            payload: const {
              'message_preview': 'We checked it from admin.',
              'actor_display_name': 'Aruzhan Ops',
            },
            createdAt: DateTime.utc(2026, 6, 20, 11, 45),
          ),
        ],
      );

      await tester.pump(const Duration(seconds: 9));
      await tester.pumpAndSettle();

      expect(api.getTicketCalls, greaterThan(1));
      expect(find.text('We checked it from admin.'), findsOneWidget);
      expect(find.text('Aruzhan Ops'), findsOneWidget);
    },
  );

  testWidgets(
    'SupportTicketDetailScreen shows websocket support replies immediately',
    (tester) async {
      final ws = _FakeChatWsService();
      final chatProvider = ChatProvider(
        chatApi: _FakeChatApi(
          conversations: [
            ConversationVm(
              id: 'conversation-123',
              type: 'direct',
              lastActivityAt: DateTime.utc(2026, 6, 20, 11, 30),
            ),
          ],
        ),
        wsService: ws,
      );
      addTearDown(chatProvider.dispose);
      await chatProvider.loadConversations();
      final api = _FakeHelpCenterApi(
        detail: SupportTicketDetailVm(
          ticket: _ticket(
            id: 'ticket-user-123',
            status: 'waiting_support',
            conversationId: 'conversation-123',
          ),
          events: [
            SupportTicketEventVm(
              ticketId: 'ticket-user-123',
              actorId: 'user-123',
              actorType: 'user',
              eventType: 'user_replied',
              payload: const {
                'message_preview': 'Can you check my booking?',
                'actor_nickname': '@nomad',
              },
              createdAt: DateTime.utc(2026, 6, 20, 11, 30),
            ),
          ],
        ),
      );

      await tester.pumpWidget(
        _testAppWithChatProvider(
          chatProvider: chatProvider,
          child: SupportTicketDetailScreen(
            ticketId: 'ticket-user-123',
            api: api,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Realtime answer from support.'), findsNothing);

      ws.addEvent(
        ChatEvent(
          eventId: 'event-agent-reply-1',
          type: 'message_sent',
          conversationId: 'conversation-123',
          payload: {
            'id': 'message-agent-1',
            'senderUserId': 'support-agent-1',
            'senderDisplayName': 'Aruzhan Ops',
            'type': 'text',
            'content': 'Realtime answer from support.',
            'sentAt': DateTime.utc(2026, 6, 20, 11, 45).toIso8601String(),
          },
          timestamp: DateTime.utc(2026, 6, 20, 11, 45),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(ws.connected, isTrue);
      expect(api.getTicketCalls, 1);
      expect(find.text('Realtime answer from support.'), findsOneWidget);
      expect(find.text('Aruzhan Ops'), findsOneWidget);
    },
  );

  testWidgets(
    'SupportTicketDetailScreen shows send status and retries failed reply',
    (tester) async {
      final firstReply = Completer<SupportTicketVm>();
      final secondReply = Completer<SupportTicketVm>();
      final api = _FakeHelpCenterApi(
        detail: SupportTicketDetailVm(
          ticket: _ticket(id: 'ticket-user-123', status: 'waiting_user'),
          events: [
            SupportTicketEventVm(
              ticketId: 'ticket-user-123',
              actorId: 'agent-1',
              actorType: 'support_agent',
              eventType: 'agent_replied',
              payload: const {'message_preview': 'Please send the receipt.'},
              createdAt: DateTime.utc(2026, 6, 20, 11, 30),
            ),
          ],
        ),
        replyResult: _ticket(id: 'ticket-user-123', status: 'waiting_support'),
        replyCompleters: [firstReply, secondReply],
      );

      await tester.pumpWidget(
        _testApp(
          SupportTicketDetailScreen(ticketId: 'ticket-user-123', api: api),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('support-ticket-reply-field')),
        'Network is shaky.',
      );
      await tester.tap(find.byKey(const ValueKey('support-ticket-send-reply')));
      await tester.pump();

      expect(find.text('Network is shaky.'), findsOneWidget);
      expect(find.text('Sending'), findsOneWidget);

      firstReply.completeError(Exception('offline'));
      await tester.pump();
      await tester.pump();

      expect(api.replyCalls, 1);
      expect(find.text('Not sent'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(find.text('Sending'), findsOneWidget);

      secondReply.complete(
        _ticket(id: 'ticket-user-123', status: 'waiting_support'),
      );
      await tester.pumpAndSettle();

      expect(api.replyCalls, 2);
      expect(find.text('Sent'), findsOneWidget);
      expect(find.text('Not sent'), findsNothing);
    },
  );

  testWidgets(
    'SupportTicketDetailScreen uploads attachment and sends file ids',
    (tester) async {
      final api = _FakeHelpCenterApi(
        detail: SupportTicketDetailVm(
          ticket: _ticket(id: 'ticket-user-123', status: 'waiting_user'),
          events: const [],
        ),
      );
      final fileApi = _FakeFileApi();

      await tester.pumpWidget(
        _testApp(
          SupportTicketDetailScreen(
            ticketId: 'ticket-user-123',
            api: api,
            fileApi: fileApi,
            attachmentPicker: () async => [
              SupportPickedAttachment(
                name: 'receipt.pdf',
                contentType: 'application/pdf',
                bytes: Uint8List.fromList([1, 2, 3]),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('support-ticket-attach-file')),
      );
      await tester.pumpAndSettle();

      expect(find.text('receipt.pdf'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('support-ticket-reply-field')),
        'Receipt attached.',
      );
      await tester.tap(find.byKey(const ValueKey('support-ticket-send-reply')));
      await tester.pumpAndSettle();

      expect(fileApi.createdNames, ['receipt.pdf']);
      expect(fileApi.uploadedFileIds, ['support-file-1']);
      expect(fileApi.completedFileIds, ['support-file-1']);
      expect(api.lastReplyFileIds, ['support-file-1']);
      expect(find.text('receipt.pdf'), findsOneWidget);
      expect(find.text('Sent'), findsOneWidget);
    },
  );

  testWidgets(
    'SupportTicketDetailScreen renders attachment chips without raw file ids',
    (tester) async {
      final api = _FakeHelpCenterApi(
        detail: SupportTicketDetailVm(
          ticket: _ticket(id: 'ticket-user-123', status: 'waiting_support'),
          events: [
            SupportTicketEventVm(
              ticketId: 'ticket-user-123',
              actorId: 'user-123',
              actorType: 'user',
              eventType: 'user_replied',
              payload: const {
                'message_preview': 'Receipt attached.',
                'file_ids': 'support-file-1,support-file-2',
                'attachment_count': '2',
              },
              createdAt: DateTime.utc(2026, 6, 20, 12),
            ),
          ],
        ),
      );

      await tester.pumpWidget(
        _testApp(
          SupportTicketDetailScreen(ticketId: 'ticket-user-123', api: api),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Receipt attached.'), findsOneWidget);
      expect(find.text('File 1'), findsOneWidget);
      expect(find.text('File 2'), findsOneWidget);
      expect(find.text('support-file-1'), findsNothing);
      expect(find.text('support-file-2'), findsNothing);
    },
  );

  testWidgets('SupportTicketDetailScreen opens single support conversation', (
    tester,
  ) async {
    final api = _FakeHelpCenterApi(
      detail: SupportTicketDetailVm(
        ticket: _ticket(id: 'ticket-single-chat', status: 'waiting_support'),
        events: [
          SupportTicketEventVm(
            ticketId: 'ticket-single-chat',
            actorId: 'user-123',
            actorType: 'user',
            eventType: 'user_replied',
            payload: const {'message_preview': 'Нужна помощь.'},
            createdAt: DateTime.utc(2026, 6, 20, 12),
          ),
        ],
      ),
      replyResult: _ticket(id: 'ticket-single-chat', status: 'waiting_support'),
    );

    await tester.pumpWidget(_testApp(SupportTicketDetailScreen(api: api)));
    await tester.pumpAndSettle();

    expect(api.getConversationCalls, 1);
    expect(find.text('Нужна помощь.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('support-ticket-reply-field')),
      'Спасибо, жду ответ.',
    );
    await tester.tap(find.byKey(const ValueKey('support-ticket-send-reply')));
    await tester.pumpAndSettle();

    expect(api.lastReplyTicketId, 'ticket-single-chat');
    expect(api.lastReplyMessage, 'Спасибо, жду ответ.');
  });

  testWidgets(
    'SupportTicketDetailScreen opens contextual support chat as one conversation',
    (tester) async {
      final api = _FakeHelpCenterApi(
        detail: SupportTicketDetailVm(
          ticket: _ticket(id: 'ticket-contextual', status: 'waiting_support'),
          events: [
            SupportTicketEventVm(
              ticketId: 'ticket-contextual',
              actorId: 'system',
              actorType: 'system',
              eventType: 'ticket_created',
              payload: const {'source': 'activity_details'},
              createdAt: DateTime.utc(2026, 6, 20, 12),
            ),
            SupportTicketEventVm(
              ticketId: 'ticket-contextual',
              actorId: 'user-123',
              actorType: 'user',
              eventType: 'user_replied',
              payload: const {'message_preview': 'Не нашел ответ по оплате.'},
              createdAt: DateTime.utc(2026, 6, 20, 12, 1),
            ),
          ],
        ),
      );

      await tester.pumpWidget(
        _testApp(
          SupportTicketDetailScreen(
            api: api,
            initialIntent: const SupportChatOpenIntent(
              category: SupportTicketCategory.activities,
              source: 'activity_details',
              intent: 'article:payment-help',
              context: {
                'activity_id': 'activity-123',
                'article_id': 'payment-help',
                'source_route': '/activities/activity-123',
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(api.createTicketCalls, 1);
      expect(api.getConversationCalls, 1);
      expect(api.lastCreateTicketCategory, SupportTicketCategory.activities);
      expect(api.lastCreateTicketSource, 'activity_details');
      expect(api.lastCreateTicketContext?['activity_id'], 'activity-123');
      expect(api.lastCreateTicketContext?['article_id'], 'payment-help');
      expect(find.text('Не нашел ответ по оплате.'), findsOneWidget);
      expect(find.text('ticket-contextual'), findsNothing);
    },
  );

  testWidgets(
    'SupportTicketDetailScreen defers failed search ticket creation until first reply',
    (tester) async {
      final api = _FakeHelpCenterApi(
        detail: SupportTicketDetailVm(
          ticket: _ticket(id: 'ticket-current', status: 'waiting_support'),
          events: const [],
        ),
        replyResult: _ticket(id: 'ticket-created', status: 'waiting_support'),
      );

      await tester.pumpWidget(
        _testApp(
          SupportTicketDetailScreen(
            api: api,
            initialIntent: const SupportChatOpenIntent(
              category: SupportTicketCategory.technical,
              source: 'help_center',
              intent: 'failed_search:unknown question',
              context: {
                'failed_search': 'unknown question',
                'search_query': 'unknown question',
                'screen': 'help_center',
                'source_route': '/help',
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(api.getConversationCalls, 1);
      expect(api.createTicketCalls, 0);

      await tester.enterText(
        find.byKey(const ValueKey('support-ticket-reply-field')),
        'I still need help.',
      );
      await tester.tap(find.byKey(const ValueKey('support-ticket-send-reply')));
      await tester.pumpAndSettle();

      expect(api.createTicketCalls, 1);
      expect(api.lastCreateTicketSource, 'help_center');
      expect(api.lastCreateTicketContext?['failed_search'], 'unknown question');
      expect(api.replyCalls, 1);
      expect(api.lastReplyTicketId, 'ticket-created');
      expect(find.text('Created new request'), findsOneWidget);
    },
  );

  testWidgets(
    'SupportTicketDetailScreen shows support episodes as chat history',
    (tester) async {
      final api = _FakeHelpCenterApi(
        detail: SupportTicketDetailVm(
          ticket: _ticket(id: 'ticket-latest', status: 'waiting_support'),
          events: [
            SupportTicketEventVm(
              ticketId: 'ticket-older',
              actorId: 'user-123',
              actorType: 'user',
              eventType: 'ticket_created',
              payload: const {'source': 'help_center'},
              createdAt: DateTime.utc(2026, 6, 18, 9),
            ),
            SupportTicketEventVm(
              ticketId: 'ticket-older',
              actorId: 'agent-1',
              actorType: 'support_agent',
              eventType: 'ticket_resolved',
              payload: const {'resolution': 'Done.'},
              createdAt: DateTime.utc(2026, 6, 18, 10),
            ),
            SupportTicketEventVm(
              ticketId: 'ticket-latest',
              actorId: 'user-123',
              actorType: 'user',
              eventType: 'ticket_created',
              payload: const {'source': 'support_chat'},
              createdAt: DateTime.utc(2026, 6, 20, 12),
            ),
            SupportTicketEventVm(
              ticketId: 'ticket-latest',
              actorId: 'user-123',
              actorType: 'user',
              eventType: 'user_replied',
              payload: const {'message_preview': 'Нужна помощь.'},
              createdAt: DateTime.utc(2026, 6, 20, 12, 1),
            ),
          ],
        ),
      );

      await tester.pumpWidget(_testApp(SupportTicketDetailScreen(api: api)));
      await tester.pumpAndSettle();

      expect(find.text('Support request from Jun 18'), findsOneWidget);
      expect(find.text('Support request from Jun 20'), findsOneWidget);
      expect(find.text('Resolved'), findsOneWidget);
      expect(find.text('Нужна помощь.'), findsOneWidget);
      expect(find.text('ticket-older'), findsNothing);
      expect(find.text('ticket-latest'), findsNothing);
    },
  );

  testWidgets(
    'SupportTicketDetailScreen does not ask for CSAT again when ticket already has rating event',
    (tester) async {
      final api = _FakeHelpCenterApi(
        detail: SupportTicketDetailVm(
          ticket: _ticket(id: 'ticket-user-123', status: 'resolved'),
          events: [
            SupportTicketEventVm(
              ticketId: 'ticket-user-123',
              actorId: 'user-123',
              actorType: 'user',
              eventType: 'ticket_csat_submitted',
              payload: const {'rating': '5'},
              createdAt: DateTime.utc(2026, 6, 20, 12),
            ),
          ],
        ),
      );

      await tester.pumpWidget(
        _testApp(
          SupportTicketDetailScreen(ticketId: 'ticket-user-123', api: api),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Rate support'), findsNothing);
      expect(find.text('Thanks for rating support'), findsOneWidget);
    },
  );

  testWidgets(
    'SupportTicketDetailScreen creates a new request when replying from resolved chat',
    (tester) async {
      final api = _FakeHelpCenterApi(
        detail: SupportTicketDetailVm(
          ticket: _ticket(id: 'ticket-resolved', status: 'resolved'),
          events: [
            SupportTicketEventVm(
              ticketId: 'ticket-resolved',
              actorId: 'agent-1',
              actorType: 'support_agent',
              eventType: 'ticket_resolved',
              payload: const {'resolution': 'Done.'},
              createdAt: DateTime.utc(2026, 6, 20, 12),
            ),
          ],
        ),
        replyResult: _ticket(id: 'ticket-created', status: 'waiting_support'),
      );

      await tester.pumpWidget(
        _testApp(
          SupportTicketDetailScreen(ticketId: 'ticket-resolved', api: api),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('support-ticket-reply-field')),
        'I have a new question.',
      );
      await tester.tap(find.byKey(const ValueKey('support-ticket-send-reply')));
      await tester.pumpAndSettle();

      expect(api.createTicketCalls, 1);
      expect(
        api.lastCreateTicketContext?['previous_ticket_id'],
        'ticket-resolved',
      );
      expect(api.lastCreateTicketContext?.containsKey('entity_id'), isFalse);
      expect(api.lastReplyTicketId, 'ticket-created');
      expect(api.lastReplyMessage, 'I have a new question.');
      expect(find.text('Created new request'), findsOneWidget);
      expect(find.text('Waiting for support'), findsOneWidget);
    },
  );

  testWidgets('SupportTicketDetailScreen localizes support system events', (
    tester,
  ) async {
    final api = _FakeHelpCenterApi(
      detail: SupportTicketDetailVm(
        ticket: _ticket(id: 'ticket-user-123', status: 'closed'),
        events: [
          SupportTicketEventVm(
            ticketId: 'ticket-user-123',
            actorId: 'user-123',
            actorType: 'user',
            eventType: 'ticket_closed_by_user',
            payload: const {'reason': 'closed_from_mobile'},
            createdAt: DateTime.utc(2026, 6, 20, 12),
          ),
          SupportTicketEventVm(
            ticketId: 'ticket-user-123',
            actorId: 'user-123',
            actorType: 'user',
            eventType: 'ticket_csat_submitted',
            payload: const {'rating': '5'},
            createdAt: DateTime.utc(2026, 6, 20, 12, 1),
          ),
          SupportTicketEventVm(
            ticketId: 'ticket-user-123',
            actorId: 'system',
            actorType: 'system',
            eventType: 'ticket_segment_calculated',
            payload: const {'customer_segment': 'guide'},
            createdAt: DateTime.utc(2026, 6, 20, 12, 2),
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      _testApp(
        SupportTicketDetailScreen(ticketId: 'ticket-user-123', api: api),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Request closed by user'), findsOneWidget);
    expect(find.text('Support rating submitted'), findsOneWidget);
    expect(find.text('System'), findsWidgets);
    expect(find.text('ticket_closed_by_user'), findsNothing);
    expect(find.text('ticket_csat_submitted'), findsNothing);
    expect(find.text('Inflap'), findsNothing);
  });

  testWidgets('SupportTicketDetailScreen keeps reply composer at bottom', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final api = _FakeHelpCenterApi(
      detail: SupportTicketDetailVm(
        ticket: _ticket(
          id: 'ticket-user-123',
          status: 'waiting_user',
          conversationId: 'conversation-123',
        ),
        events: [
          SupportTicketEventVm(
            ticketId: 'ticket-user-123',
            actorId: 'agent-1',
            actorType: 'support_agent',
            eventType: 'agent_replied',
            payload: const {
              'message_preview': 'Please send the receipt.',
              'actor_display_name': 'Aruzhan Ops',
            },
            createdAt: DateTime.utc(2026, 6, 20, 11, 30),
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      _testApp(
        SupportTicketDetailScreen(ticketId: 'ticket-user-123', api: api),
      ),
    );
    await tester.pumpAndSettle();

    final composerFinder = find.byKey(
      const ValueKey('support-ticket-reply-composer'),
    );
    expect(composerFinder, findsOneWidget);

    final composerBottom = tester.getBottomLeft(composerFinder).dy;
    final screenHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    expect(composerBottom, greaterThan(screenHeight - 44));
  });

  testWidgets('SupportTicketDetailScreen opens at the latest message', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final api = _FakeHelpCenterApi(
      detail: SupportTicketDetailVm(
        ticket: _ticket(id: 'ticket-user-123', status: 'waiting_user'),
        events: List.generate(
          32,
          (index) => SupportTicketEventVm(
            ticketId: 'ticket-user-123',
            actorId: index.isEven ? 'user-123' : 'agent-1',
            actorType: index.isEven ? 'user' : 'support_agent',
            eventType: index.isEven ? 'user_replied' : 'agent_replied',
            payload: {
              'message_preview': index == 31
                  ? 'Latest support reply'
                  : 'Older support message $index',
            },
            createdAt: DateTime.utc(2026, 6, 20, 12, index),
          ),
        ),
      ),
    );

    await tester.pumpWidget(
      _testApp(
        SupportTicketDetailScreen(ticketId: 'ticket-user-123', api: api),
      ),
    );
    await tester.pumpAndSettle();

    final screenHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    final latestBottom = tester
        .getBottomLeft(find.text('Latest support reply'))
        .dy;

    expect(latestBottom, lessThan(screenHeight - 88));
  });

  testWidgets(
    'SupportTicketDetailScreen pins header and composer as overlays',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final api = _FakeHelpCenterApi(
        detail: SupportTicketDetailVm(
          ticket: _ticket(id: 'ticket-user-123', status: 'waiting_user'),
          events: List.generate(
            24,
            (index) => SupportTicketEventVm(
              ticketId: 'ticket-user-123',
              actorId: index.isEven ? 'user-123' : 'agent-1',
              actorType: index.isEven ? 'user' : 'support_agent',
              eventType: index.isEven ? 'user_replied' : 'agent_replied',
              payload: {'message_preview': 'Message $index'},
              createdAt: DateTime.utc(2026, 6, 20, 12, index),
            ),
          ),
        ),
      );

      await tester.pumpWidget(
        _testApp(
          SupportTicketDetailScreen(ticketId: 'ticket-user-123', api: api),
        ),
      );
      await tester.pumpAndSettle();

      final headerFinder = find.byKey(
        const ValueKey('support-ticket-header-overlay'),
      );
      final composerFinder = find.byKey(
        const ValueKey('support-ticket-input-overlay'),
      );
      expect(headerFinder, findsOneWidget);
      expect(composerFinder, findsOneWidget);

      final headerTopBefore = tester.getTopLeft(headerFinder).dy;
      final composerBottomBefore = tester.getBottomLeft(composerFinder).dy;

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -420));
      await tester.pumpAndSettle();

      expect(tester.getTopLeft(headerFinder).dy, headerTopBefore);
      expect(tester.getBottomLeft(composerFinder).dy, composerBottomBefore);
    },
  );

  testWidgets('SupportTicketDetailScreen submits CSAT for resolved ticket', (
    tester,
  ) async {
    final api = _FakeHelpCenterApi(
      detail: SupportTicketDetailVm(
        ticket: _ticket(id: 'ticket-user-123', status: 'resolved'),
        events: [
          SupportTicketEventVm(
            ticketId: 'ticket-user-123',
            actorId: 'agent-1',
            actorType: 'support_agent',
            eventType: 'ticket_resolved',
            payload: const {'resolution': 'Refund checked.'},
            createdAt: DateTime.utc(2026, 6, 20, 12),
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      _testApp(
        SupportTicketDetailScreen(ticketId: 'ticket-user-123', api: api),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Resolved'), findsOneWidget);
    expect(find.byKey(const ValueKey('support-ticket-csat-5')), findsOneWidget);
    final initialStar = tester.widget<Icon>(
      find.descendant(
        of: find.byKey(const ValueKey('support-ticket-csat-5')),
        matching: find.byIcon(Icons.star_border_rounded),
      ),
    );
    expect(initialStar.color, AppPalette.primary);

    await tester.enterText(
      find.byKey(const ValueKey('support-ticket-csat-comment')),
      'Fast and helpful.',
    );
    await tester.tap(find.byKey(const ValueKey('support-ticket-csat-5')));
    await tester.pumpAndSettle();

    final selectedStar = tester.widget<Icon>(
      find.descendant(
        of: find.byKey(const ValueKey('support-ticket-csat-5')),
        matching: find.byIcon(Icons.star_rounded),
      ),
    );
    final selectedStarButton = tester.widget<IconButton>(
      find.byKey(const ValueKey('support-ticket-csat-5')),
    );
    expect(selectedStar.color, AppPalette.primary);
    expect(
      selectedStarButton.style?.backgroundColor?.resolve(<WidgetState>{}),
      isNot(AppPalette.primary),
    );
    expect(api.lastCSATTicketId, isNull);
    expect(api.lastCSATRating, isNull);
    expect(find.text('Thanks for rating support.'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('support-ticket-csat-submit')));
    await tester.pumpAndSettle();

    expect(api.lastCSATTicketId, 'ticket-user-123');
    expect(api.lastCSATRating, 5);
    expect(api.lastCSATComment, 'Fast and helpful.');
    expect(find.text('Thanks for rating support'), findsOneWidget);
  });
}

Widget _routerTestApp(GoRouter router) {
  return MaterialApp.router(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    routerConfig: router,
  );
}

Widget _testApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}

Widget _testAppWithChatProvider({
  required ChatProvider chatProvider,
  required Widget child,
}) {
  return ChangeNotifierProvider<ChatProvider>.value(
    value: chatProvider,
    child: _testApp(child),
  );
}

SupportTicketVm _ticket({
  required String id,
  required String status,
  String conversationId = '',
  String source = 'help_center',
  String priority = 'normal',
  DateTime? createdAt,
  DateTime? firstResponseAt,
}) {
  return SupportTicketVm(
    id: id,
    conversationId: conversationId,
    status: status,
    category: SupportTicketCategory.technical,
    priority: priority,
    source: source,
    locale: 'en',
    context: const {},
    firstResponseAt: firstResponseAt,
    lastMessageAt: DateTime.utc(2026, 6, 20, 12),
    createdAt: createdAt ?? DateTime.utc(2026, 6, 20, 11),
    updatedAt: DateTime.utc(2026, 6, 20, 12),
  );
}

class _FakeHelpCenterApi extends HelpCenterApi {
  _FakeHelpCenterApi({
    this.tickets = const [],
    SupportTicketDetailVm? detail,
    SupportTicketVm? replyResult,
    List<Completer<SupportTicketVm>> replyCompleters = const [],
  }) : detail =
           detail ??
           SupportTicketDetailVm(
             ticket: _ticket(id: 'ticket-user-123', status: 'waiting_user'),
             events: const [],
           ),
       replyResult =
           replyResult ??
           _ticket(id: 'ticket-user-123', status: 'waiting_support'),
       replyCompleters = List<Completer<SupportTicketVm>>.of(replyCompleters);

  final List<SupportTicketVm> tickets;
  SupportTicketDetailVm detail;
  final SupportTicketVm replyResult;
  final List<Completer<SupportTicketVm>> replyCompleters;
  int listCalls = 0;
  int getTicketCalls = 0;
  int getConversationCalls = 0;
  int replyCalls = 0;
  String? lastReplyTicketId;
  String? lastReplyMessage;
  List<String> lastReplyFileIds = const [];
  int createTicketCalls = 0;
  SupportTicketCategory? lastCreateTicketCategory;
  String? lastCreateTicketSource;
  Map<String, String>? lastCreateTicketContext;
  String? lastCSATTicketId;
  int? lastCSATRating;
  String? lastCSATComment;

  @override
  Future<List<SupportTicketVm>> listSupportTickets({
    String? status,
    int? limit,
    int? offset,
  }) async {
    listCalls += 1;
    return tickets;
  }

  @override
  Future<SupportTicketVm> createSupportTicket({
    required SupportTicketCategory category,
    required String source,
    required String locale,
    Map<String, String> context = const {},
    String? idempotencyKey,
  }) async {
    createTicketCalls += 1;
    lastCreateTicketCategory = category;
    lastCreateTicketSource = source;
    lastCreateTicketContext = context;
    return _ticket(id: 'ticket-created', status: 'new', source: source);
  }

  @override
  Future<SupportTicketDetailVm> getSupportTicket(String ticketId) async {
    getTicketCalls += 1;
    return detail;
  }

  @override
  Future<SupportTicketDetailVm> getSupportConversation({
    required String locale,
  }) async {
    getConversationCalls += 1;
    return detail;
  }

  @override
  Future<SupportTicketVm> replyToSupportTicket({
    required String ticketId,
    required String message,
    String? actorNickname,
    List<String> fileIds = const [],
    String? idempotencyKey,
  }) async {
    replyCalls += 1;
    lastReplyTicketId = ticketId;
    lastReplyMessage = message;
    lastReplyFileIds = fileIds;
    if (replyCompleters.isNotEmpty) {
      return replyCompleters.removeAt(0).future;
    }
    detail = SupportTicketDetailVm(
      ticket: replyResult,
      events: [
        ...detail.events,
        SupportTicketEventVm(
          ticketId: ticketId,
          actorId: 'user-123',
          actorType: 'user',
          eventType: 'user_replied',
          payload: {'message_preview': message, 'actor_nickname': '@nomad'},
          createdAt: DateTime.utc(2026, 6, 20, 12),
        ),
      ],
    );
    return replyResult;
  }

  @override
  Future<void> submitSupportTicketCSAT({
    required String ticketId,
    required int rating,
    String? comment,
  }) async {
    lastCSATTicketId = ticketId;
    lastCSATRating = rating;
    lastCSATComment = comment;
  }
}

class _FakeChatApi extends ChatApi {
  _FakeChatApi({this.conversations = const []});

  final List<ConversationVm> conversations;

  @override
  Future<List<ConversationVm>> listConversations({
    int limit = 20,
    String? type,
    String? cursor,
  }) async {
    return conversations;
  }
}

class _FakeChatWsService extends ChatWsService {
  final _controller = StreamController<ChatEvent>.broadcast();
  var connected = false;

  @override
  Stream<ChatEvent> get events => _controller.stream;

  @override
  bool get isConnected => connected;

  @override
  Future<void> connect() async {
    connected = true;
  }

  @override
  void disconnect() {
    connected = false;
  }

  @override
  void dispose() {
    connected = false;
    _controller.close();
  }

  void addEvent(ChatEvent event) {
    _controller.add(event);
  }
}

class _FakeFileApi extends FileApi {
  final createdNames = <String>[];
  final uploadedFileIds = <String>[];
  final completedFileIds = <String>[];

  @override
  Future<FileUploadRequestVm> createChatAttachmentUpload({
    required String originalName,
    required String contentType,
    required int sizeBytes,
  }) async {
    createdNames.add(originalName);
    final fileId = 'support-file-${createdNames.length}';
    return FileUploadRequestVm(
      fileId: fileId,
      objectKey: fileId,
      status: 'PENDING',
      method: 'PUT',
      url: 'https://upload.test/$fileId',
      headers: const {},
    );
  }

  @override
  Future<void> uploadBinary({
    required FileUploadRequestVm upload,
    required Uint8List bytes,
    required String contentType,
  }) async {
    uploadedFileIds.add(upload.fileId);
  }

  @override
  Future<void> completeUpload(String fileId) async {
    completedFileIds.add(fileId);
  }
}
