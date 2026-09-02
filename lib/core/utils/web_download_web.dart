import 'dart:convert' show utf8;
import 'dart:html' as html;

void downloadCsvBytes(List<int> bytes, String fileName) {
  final blob = html.Blob([bytes], 'text/csv');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}
