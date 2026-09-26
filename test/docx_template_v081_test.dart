import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('v0.8.1 MASTER template has no duplicate-prone drawing objects', () async {
    final data = await rootBundle.load('assets/templates/report_template.docx');
    final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    final archive = ZipDecoder().decodeBytes(bytes);
    final xmlFile = archive.findFile('word/document.xml');

    expect(xmlFile, isNotNull);
    final xml = utf8.decode(xmlFile!.content as List<int>);

    expect(xml.contains('<mc:AlternateContent'), isFalse);
    expect(xml.contains('<wp:docPr'), isFalse);
    expect(xml.contains('<v:shape'), isFalse);
    expect(xml.contains('{{H1}}'), isFalse);
    expect(xml.contains('{{H2}}'), isFalse);
  });

  test('v0.8.1 MASTER template has no empty tail paragraphs', () async {
    final data = await rootBundle.load('assets/templates/report_template.docx');
    final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    final archive = ZipDecoder().decodeBytes(bytes);
    final xml = utf8.decode(
      archive.findFile('word/document.xml')!.content as List<int>,
    );

    final body = RegExp(
      r'<w:body>([\s\S]*?)(<w:sectPr[\s\S]*?</w:sectPr>)\s*</w:body>',
    ).firstMatch(xml);
    expect(body, isNotNull);

    final content = body!.group(1)!;
    final paragraphs = RegExp(r'<w:p\b[^>]*>[\s\S]*?</w:p>')
        .allMatches(content)
        .map((match) => match.group(0)!)
        .toList();

    expect(paragraphs.length, greaterThanOrEqualTo(2));

    final textNode = RegExp(r'<w:t\b[^>]*>([\s\S]*?)</w:t>');
    String paragraphText(String paragraph) => textNode
        .allMatches(paragraph)
        .map((item) => item.group(1) ?? '')
        .join()
        .trim();

    final beforeLastText = paragraphText(paragraphs[paragraphs.length - 2]);
    final lastText = paragraphText(paragraphs.last);

    // The template must end with the order line and its date/number line.
    // If an empty paragraph is appended after them, lastText would be empty.
    expect(beforeLastText, contains('Наказ начальника ІСЗЗІ'));
    expect(lastText, contains('{{РІК}}'));
    expect(lastText, contains('№'));
    expect(lastText, isNotEmpty);
  });

  test('v0.8.1 MASTER supports three-line addressees', () async {
    final data = await rootBundle.load('assets/templates/report_template.docx');
    final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    final archive = ZipDecoder().decodeBytes(bytes);
    final xml = utf8.decode(
      archive.findFile('word/document.xml')!.content as List<int>,
    );

    expect(xml.contains('{{R2_3}}'), isTrue);
    expect(xml.contains('{{R3_3}}'), isTrue);
  });
}
