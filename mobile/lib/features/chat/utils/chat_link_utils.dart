class ChatLinkMatch {
  const ChatLinkMatch({
    required this.start,
    required this.end,
    required this.url,
  });

  final int start;
  final int end;
  final String url;
}

final chatUrlRegex = RegExp(
  r'((?:https?:\/\/|flyfy:\/\/|www\.|\/(?:activities|attractions|chats|map|me|profile|stories|excursions|users)\b)[^\s<>()]*)',
  caseSensitive: false,
);

List<ChatLinkMatch> extractChatLinks(String text) {
  final links = <ChatLinkMatch>[];
  for (final match in chatUrlRegex.allMatches(text)) {
    final rawUrl = match.group(0) ?? '';
    final cleanedUrl = cleanChatUrl(rawUrl);
    if (cleanedUrl.isEmpty) continue;

    links.add(
      ChatLinkMatch(
        start: match.start,
        end: match.end - (rawUrl.length - cleanedUrl.length),
        url: cleanedUrl,
      ),
    );
  }
  return links;
}

String cleanChatUrl(String rawUrl) {
  return rawUrl.trim().replaceFirst(RegExp(r'[),.;!?]+$'), '');
}

Uri? externalUriForChatUrl(String rawUrl) {
  final trimmed = rawUrl.trim();
  if (trimmed.isEmpty) return null;

  final normalized = trimmed.startsWith('www.') ? 'https://$trimmed' : trimmed;
  final uri = Uri.tryParse(normalized);
  if (uri == null) return null;
  final scheme = uri.scheme.toLowerCase();
  if (scheme == 'http' || scheme == 'https') return uri;
  return null;
}

String chatLinkHostLabel(String rawUrl) {
  final internalRoute = internalAppRouteForChatUrl(rawUrl);
  if (internalRoute != null) return 'FlyFy';

  final externalUri = externalUriForChatUrl(rawUrl);
  final host = externalUri?.host.trim() ?? '';
  if (host.isNotEmpty) {
    return host.replaceFirst(RegExp(r'^www\.', caseSensitive: false), '');
  }

  final fallback = rawUrl.trim();
  return fallback.isEmpty ? 'link' : fallback;
}

String? internalAppRouteForChatUrl(String rawUrl) {
  final trimmed = rawUrl.trim();
  if (trimmed.isEmpty) return null;

  if (trimmed.startsWith('/')) {
    return knownInternalChatRoute(trimmed);
  }

  final normalized = trimmed.startsWith('www.') ? 'https://$trimmed' : trimmed;
  final uri = Uri.tryParse(normalized);
  if (uri == null) return null;

  final scheme = uri.scheme.toLowerCase();
  if (scheme == 'flyfy') {
    final path = uri.host.isEmpty ? uri.path : '/${uri.host}${uri.path}';
    return knownInternalChatRoute(routeWithQuery(path, uri.query));
  }

  final host = uri.host.toLowerCase();
  if ((scheme == 'http' || scheme == 'https') &&
      (host == 'flyfy.app' || host.endsWith('.flyfy.app'))) {
    return knownInternalChatRoute(routeWithQuery(uri.path, uri.query));
  }

  return null;
}

String? knownInternalChatRoute(String route) {
  final uri = Uri.tryParse(route);
  if (uri == null) return null;
  final path = uri.path;
  if (path == '/profile' ||
      path.startsWith('/profile/') ||
      path == '/map' ||
      path == '/me/activities' ||
      path.startsWith('/activities/') ||
      path.startsWith('/attractions/') ||
      path.startsWith('/chats/') ||
      path.startsWith('/stories/') ||
      path.startsWith('/excursions/') ||
      path.startsWith('/users/')) {
    return route;
  }
  return null;
}

String routeWithQuery(String path, String query) {
  final routePath = path.isEmpty ? '/' : path;
  if (query.isEmpty) return routePath;
  return '$routePath?$query';
}
