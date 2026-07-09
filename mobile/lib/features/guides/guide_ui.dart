const double guideGridMinTwoColumnWidth = 288;
const double guideGridLargeTextMinTwoColumnWidth = 320;
const double guideGridExpandedThreeColumnWidth = 680;
const double guideGridVeryLargeTextScale = 1.45;

int guideGridColumnCount({
  required double crossAxisExtent,
  required double textScale,
}) {
  if (!crossAxisExtent.isFinite || crossAxisExtent <= 0) return 1;

  final effectiveTextScale = textScale.isFinite ? textScale : 1.0;
  if (crossAxisExtent >= guideGridExpandedThreeColumnWidth) return 3;
  if (effectiveTextScale >= guideGridVeryLargeTextScale &&
      crossAxisExtent < guideGridLargeTextMinTwoColumnWidth) {
    return 1;
  }

  return crossAxisExtent < guideGridMinTwoColumnWidth ? 1 : 2;
}
