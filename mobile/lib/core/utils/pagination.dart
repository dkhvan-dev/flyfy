import 'dart:math' as math;

class PaginationSlice<T> {
  const PaginationSlice({
    required this.items,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
  });

  final List<T> items;
  final int currentPage;
  final int totalPages;
  final int totalItems;

  bool get hasMultiplePages => totalPages > 1;
}

PaginationSlice<T> paginateItems<T>(
  List<T> items, {
  required int currentPage,
  required int pageSize,
}) {
  final safePageSize = math.max(1, pageSize);
  final totalPages = math.max(1, (items.length / safePageSize).ceil());
  final page = currentPage.clamp(1, totalPages).toInt();
  final start = (page - 1) * safePageSize;
  final end = math.min(start + safePageSize, items.length);

  return PaginationSlice<T>(
    items: items.sublist(start, end),
    currentPage: page,
    totalPages: totalPages,
    totalItems: items.length,
  );
}
