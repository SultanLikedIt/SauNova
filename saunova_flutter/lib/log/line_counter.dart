import 'dart:io';

// ignore_for_file: avoid_print

void main() async {
  final directory = Directory('lib');
  if (!await directory.exists()) {
    print('The lib directory does not exist.');
    return;
  }

  int totalLines = 0;
  int totalDartFiles = 0;
  String mostLines = '';
  int mostLinesCount = 0;

  await for (final file in directory.list(recursive: true)) {
    if (file is File && file.path.endsWith('.dart')) {
      totalDartFiles++;
      final lines = await _countLines(file);
      totalLines += lines;
      if (lines > mostLinesCount) {
        mostLinesCount = lines;
        mostLines = file.path;
      }
    }
  }

  print('Total lines of code: $totalLines');
  print('File with most lines: $mostLines');
  print('Number of lines: $mostLinesCount');
  print('Total number of dart files: $totalDartFiles');
}

Future<int> _countLines(File file) async {
  final lines = await file.readAsLines();
  return lines.length;
}
