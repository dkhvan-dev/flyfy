import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/ui/app_bottom_navigation_bars.dart';
import '../../core/ui/app_colors.dart';
import '../../features/services/service_catalog.dart';
import '../../features/services/widgets/service_grid.dart';
import '../../l10n/generated/app_localizations.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  void _openService(BuildContext context, TravelServiceEntry service) {
    if (!service.isAvailable || service.route.trim().isEmpty) return;
    context.push(service.route);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final services = buildTravelServiceCatalog(l10n);

    return Scaffold(
      backgroundColor: const Color(0xFF160D07),
      bottomNavigationBar: CommonBottomNavigationBar(
        activeItem: AppBottomNavItem.services,
        onHomeTap: () => context.go('/'),
        onQrTap: () => context.push('/qr'),
        onMapTap: () => context.push('/map'),
        onServicesTap: () {},
        onChatsTap: () => context.push('/chats'),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(color: Color(0xFF21180D)),
        child: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 375;
              final horizontalPadding = isCompact ? 13.0 : 16.0;

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      isCompact ? 24 : 30,
                      horizontalPadding,
                      32,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ServicesHeader(title: l10n.servicesSectionTitle),
                          SizedBox(height: isCompact ? 24 : 30),
                          ServiceGrid(
                            services: services,
                            onServiceTap: (service) =>
                                _openService(context, service),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ServicesHeader extends StatelessWidget {
  const _ServicesHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 375;

    return Row(
      children: [
        IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
              return;
            }
            context.go('/');
          },
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: AppColors.textPrimary,
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: isCompact ? 28 : 32,
              height: 1.1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}
