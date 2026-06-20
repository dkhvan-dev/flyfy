import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';

class TravelServiceEntry {
  const TravelServiceEntry({
    required this.title,
    required this.icon,
    required this.route,
    this.isAvailable = true,
  });

  final String title;
  final IconData icon;
  final String route;
  final bool isAvailable;
}

List<TravelServiceEntry> buildTravelServiceCatalog(AppLocalizations l10n) {
  return [
    TravelServiceEntry(
      title: l10n.homeServiceActivities,
      icon: Icons.hiking_rounded,
      route: '/activities',
    ),
    TravelServiceEntry(
      title: l10n.serviceExcursions,
      icon: Icons.travel_explore_rounded,
      route: '/excursions',
    ),
    TravelServiceEntry(
      title: l10n.serviceGuides,
      icon: Icons.flag_rounded,
      route: '/guides',
    ),
    TravelServiceEntry(
      title: l10n.feedNavLabel,
      icon: Icons.dynamic_feed_rounded,
      route: '/feed',
    ),
    TravelServiceEntry(
      title: l10n.homeServicePlaces,
      icon: Icons.account_balance_rounded,
      route: '/places',
    ),
    TravelServiceEntry(
      title: l10n.homeServiceCurrencyConverter,
      icon: Icons.currency_exchange_rounded,
      route: '/currency-converter',
    ),
    TravelServiceEntry(
      title: l10n.homeServiceStays,
      icon: Icons.bed_rounded,
      route: '/featured-stays',
      isAvailable: false,
    ),
    TravelServiceEntry(
      title: l10n.serviceTransport,
      icon: Icons.directions_car_filled_rounded,
      route: '/car-rentals',
      isAvailable: false,
    ),
    TravelServiceEntry(
      title: l10n.homeServiceDelivery,
      icon: Icons.delivery_dining_rounded,
      route: '/glovo',
      isAvailable: false,
    ),
    TravelServiceEntry(
      title: l10n.homeServiceTaxi,
      icon: Icons.local_taxi_rounded,
      route: '/yandex-go',
      isAvailable: false,
    ),
  ];
}
