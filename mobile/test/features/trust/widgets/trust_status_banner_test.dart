import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inflap/features/trust/widgets/trust_moderation_action_bar.dart';
import 'package:inflap/features/trust/widgets/trust_status_banner.dart';

void main() {
  testWidgets('renders blocked muted pending and rejected trust banners', (
    tester,
  ) async {
    var actionTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              TrustStatusBanner(
                kind: TrustStatusBannerKind.blocked,
                title: 'Account restricted',
                message: 'Some actions are temporarily unavailable.',
                actionLabel: 'Appeal',
                onAction: () => actionTapped = true,
              ),
              const TrustStatusBanner(
                kind: TrustStatusBannerKind.muted,
                title: 'Notifications muted',
                message: 'You can unmute this conversation at any time.',
              ),
              const TrustStatusBanner(
                kind: TrustStatusBannerKind.pendingAppeal,
                title: 'Appeal pending',
                message: 'Moderators are reviewing your appeal.',
              ),
              const TrustStatusBanner(
                kind: TrustStatusBannerKind.rejected,
                title: 'Appeal rejected',
                message: 'The restriction remains active after review.',
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Account restricted'), findsOneWidget);
    expect(find.text('Notifications muted'), findsOneWidget);
    expect(find.text('Appeal pending'), findsOneWidget);
    expect(find.text('Appeal rejected'), findsOneWidget);

    await tester.tap(find.text('Appeal'));
    expect(actionTapped, isTrue);
  });

  testWidgets('keeps long localized copy and appeal CTA inside compact width', (
    tester,
  ) async {
    var actionTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 720),
              textScaler: TextScaler.linear(1.45),
            ),
            child: Center(
              child: SizedBox(
                width: 280,
                child: TrustStatusBanner(
                  kind: TrustStatusBannerKind.blocked,
                  title:
                      'Your posting and joining permissions are temporarily restricted',
                  message:
                      'Community moderators found activity that may need additional review before your account can continue with all social actions.',
                  actionLabel: 'Send moderation appeal',
                  onAction: () => actionTapped = true,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Send moderation appeal'));
    expect(actionTapped, isTrue);
  });

  testWidgets('trust moderation action bar invokes injected callbacks', (
    tester,
  ) async {
    var reportCount = 0;
    var muteCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TrustModerationActionBar(
            reportLabel: 'Report',
            muteLabel: 'Mute author',
            onReport: () async => reportCount++,
            onMute: () async => muteCount++,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Report'));
    await tester.pump();
    await tester.tap(find.text('Mute author'));
    await tester.pump();

    expect(reportCount, 1);
    expect(muteCount, 1);
  });

  testWidgets('trust moderation action bar avoids overflow with long labels', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 720),
              textScaler: TextScaler.linear(1.35),
            ),
            child: SizedBox(
              width: 260,
              child: TrustModerationActionBar(
                reportLabel: 'Report this unsafe community story',
                muteLabel: 'Mute updates from this author',
                appealLabel: 'Open moderation appeal form',
                onReport: () async {},
                onMute: () async {},
                onAppeal: () async {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Report this unsafe community story'), findsOneWidget);
    expect(find.text('Mute updates from this author'), findsOneWidget);
    expect(find.text('Open moderation appeal form'), findsOneWidget);
  });
}
