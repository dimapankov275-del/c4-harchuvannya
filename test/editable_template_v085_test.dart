import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('v0.8.5 editable Word page contains required content controls', () async {
    final data = await rootBundle.load(
      'assets/templates/report_editable_template.docx',
    );
    final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    final archive = ZipDecoder().decodeBytes(bytes);
    final xmlFile = archive.findFile('word/document.xml');

    expect(xmlFile, isNotNull);
    final xml = utf8.decode(xmlFile!.content as List<int>);

    for (final tag in <String>[
      'H1',
      'H_PERSON',
      'КОМПЕНСАЦІЇ',
      'ПІБ_ДАВ',
      'ПІДПИС',
      'R2_3',
      'R3_3',
      'DOC_NAME',
    ]) {
      expect(xml, contains('w:val="$tag"'));
    }

    expect(xml, isNot(contains('{{')));
    expect(xml, contains('<wp:docPr id="1"'));
    expect(xml, contains('HeaderTextBox_1'));
  });
}
