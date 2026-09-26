import 'package:c4_harchuvannya/report_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('v0.8.4 layout settings round-trip', () {
    const source = ReportLayoutSettings(
      pageTopMm: 10,
      pageRightMm: 12,
      pageBottomMm: 11,
      pageLeftMm: 25,
      headerColumnWidthMm: 72,
      headerWidthMm: 86,
      headerHeightMm: 28,
      headerPaddingMm: 1.5,
      headerOffsetXmm: 2,
      headerOffsetYmm: 3,
      headerFontPt: 9.5,
      bodyFontPt: 11.5,
      firstLineIndentMm: 10,
      lineSpacing: 1.15,
      gapBeforeFirstReportMm: 1,
      gapBeforePetitionMm: 2,
      gapBeforeThirdReportMm: 3,
      gapBeforeApprovalMm: 4,
      gapBeforeOrderMm: 5,
    );

    final restored = ReportLayoutSettings.fromJson(source.toJson());

    expect(restored.pageLeftMm, 25);
    expect(restored.headerWidthMm, 86);
    expect(restored.headerPaddingMm, 1.5);
    expect(restored.headerOffsetXmm, 2);
    expect(restored.headerOffsetYmm, 3);
    expect(restored.lineSpacing, 1.15);
    expect(restored.gapBeforeOrderMm, 5);
  });

  test('v0.8.4 layout defaults are usable', () {
    const d = ReportLayoutSettings.defaults;
    expect(d.pageLeftMm, greaterThan(0));
    expect(d.headerWidthMm, greaterThan(0));
    expect(d.headerHeightMm, greaterThan(0));
    expect(d.bodyFontPt, greaterThanOrEqualTo(9));
  });
}
