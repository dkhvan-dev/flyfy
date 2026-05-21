import 'models/activity_category_vm.dart';

String normalizeActivityTaxonomySlug(String? value) {
  return (value ?? '').trim().toLowerCase().replaceAll('_', '-');
}

ActivityCategoryVm? findActivityCategoryBySlug({
  required List<ActivityCategoryVm> categories,
  required String? slug,
}) {
  final normalized = normalizeActivityTaxonomySlug(slug);
  if (normalized.isEmpty) return null;

  for (final category in categories) {
    if (category.slug == normalized || category.aliases.contains(normalized)) {
      return category;
    }
  }
  return null;
}

String resolvedActivityCategorySlug({
  required List<ActivityCategoryVm> categories,
  required String? slug,
}) {
  final normalized = normalizeActivityTaxonomySlug(slug);
  if (normalized.isEmpty) return '';
  return findActivityCategoryBySlug(
        categories: categories,
        slug: normalized,
      )?.slug ??
      normalized;
}

String localizedActivityCategoryLabel({
  required List<ActivityCategoryVm> categories,
  required String? slug,
  required String languageCode,
}) {
  final normalized = normalizeActivityTaxonomySlug(slug);
  if (normalized.isEmpty) return '';

  final category = findActivityCategoryBySlug(
    categories: categories,
    slug: normalized,
  );
  if (category != null) {
    return category.localizedName(languageCode);
  }

  return ActivityCategoryVm.humanizeSlug(normalized);
}

String localizedActivitySubcategoryLabel({
  required List<ActivityCategoryVm> categories,
  required String? categorySlug,
  required String? subcategorySlug,
  required String languageCode,
}) {
  final normalized = normalizeActivityTaxonomySlug(subcategorySlug);
  if (normalized.isEmpty) return '';

  final category = findActivityCategoryBySlug(
    categories: categories,
    slug: categorySlug,
  );
  final categoryMatch = category == null
      ? null
      : _findTaxonomyItem(category.subcategories, normalized);
  if (categoryMatch != null) {
    return categoryMatch.localizedName(languageCode);
  }

  for (final item in categories) {
    final match = _findTaxonomyItem(item.subcategories, normalized);
    if (match != null) {
      return match.localizedName(languageCode);
    }
  }

  return ActivityCategoryVm.humanizeSlug(normalized);
}

String localizedActivityTagLabel({
  required List<ActivityCategoryVm> categories,
  required String? tagSlug,
  required String languageCode,
}) {
  final normalized = normalizeActivityTaxonomySlug(tagSlug);
  if (normalized.isEmpty) return '';

  for (final category in categories) {
    final match = _findTaxonomyItem(category.systemTags, normalized);
    if (match != null) {
      return match.localizedName(languageCode);
    }
  }

  return ActivityCategoryVm.humanizeSlug(normalized);
}

ActivityTaxonomyItemVm? _findTaxonomyItem(
  List<ActivityTaxonomyItemVm> items,
  String slug,
) {
  for (final item in items) {
    if (item.slug == slug) return item;
  }
  return null;
}
