import 'dart:io';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart' as xls;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../habits/presentation/providers/habit_providers.dart';

/// Exports habit data and analytics to CSV, Excel and PDF.
///
/// Files are written to the user's Documents/AuraHabits Exports folder and the
/// path is surfaced via a snackbar.
class ExportService {
  ExportService._();
  static final instance = ExportService._();

  Future<Directory> _exportDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/AuraHabits Exports');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  String _stamp() => DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());

  List<List<String>> _rows(WidgetRef ref) {
    final repo = ref.read(habitRepositoryProvider);
    final rows = <List<String>>[
      ['Habit', 'Category', 'Priority', 'Difficulty', 'Frequency', 'Current Streak', 'Best Streak', 'Completions', 'Success Rate'],
    ];
    for (final h in repo.getHabits(includeArchived: true)) {
      final s = repo.statsFor(h);
      rows.add([
        h.name,
        h.categoryId,
        h.priority.label,
        h.difficulty.label,
        h.frequency.label,
        '${s.currentStreak}',
        '${s.bestStreak}',
        '${s.totalCompleted}',
        '${(s.successRate * 100).round()}%',
      ]);
    }
    return rows;
  }

  Future<void> exportCsv(WidgetRef ref, BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final csv = const CsvEncoder().convert(_rows(ref));
      final file = File('${(await _exportDir()).path}/habits_${_stamp()}.csv');
      await file.writeAsString(csv);
      _notify(messenger, 'CSV exported', file.path);
    } catch (e) {
      _notify(messenger, 'Export failed', '$e', error: true);
    }
  }

  Future<void> exportExcel(WidgetRef ref, BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final book = xls.Excel.createExcel();
      final sheet = book['Habits'];
      for (final row in _rows(ref)) {
        sheet.appendRow(row.map((c) => xls.TextCellValue(c)).toList());
      }
      final bytes = book.encode();
      if (bytes == null) throw 'encode failed';
      final file = File('${(await _exportDir()).path}/habits_${_stamp()}.xlsx');
      await file.writeAsBytes(bytes);
      _notify(messenger, 'Excel exported', file.path);
    } catch (e) {
      _notify(messenger, 'Export failed', '$e', error: true);
    }
  }

  Future<void> exportPdf(WidgetRef ref, BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final repo = ref.read(habitRepositoryProvider);
      final habits = repo.getHabits(includeArchived: true);
      final doc = pw.Document();
      final rows = _rows(ref);

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (ctx) => [
            pw.Header(
              level: 0,
              child: pw.Text('Aura Habits — Report',
                  style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
            ),
            pw.Text('Generated ${DateFormat('MMM d, yyyy • HH:mm').format(DateTime.now())}',
                style: const pw.TextStyle(color: PdfColors.grey)),
            pw.SizedBox(height: 12),
            pw.Text('Total habits: ${habits.length}'),
            pw.SizedBox(height: 16),
            pw.TableHelper.fromTextArray(
              headers: rows.first,
              data: rows.skip(1).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
              cellAlignment: pw.Alignment.centerLeft,
            ),
          ],
        ),
      );

      final file = File('${(await _exportDir()).path}/report_${_stamp()}.pdf');
      await file.writeAsBytes(await doc.save());
      _notify(messenger, 'PDF exported', file.path);
    } catch (e) {
      _notify(messenger, 'Export failed', '$e', error: true);
    }
  }

  void _notify(ScaffoldMessengerState messenger, String title, String detail, {bool error = false}) {
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1C1C1C),
        content: Text(error ? '$title: $detail' : '$title → $detail',
            style: const TextStyle(color: Colors.white)),
        duration: const Duration(seconds: 5),
      ),
    );
  }
}
