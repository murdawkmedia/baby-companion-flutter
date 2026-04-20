import 'package:flutter/material.dart';

import '../../domain/haptics.dart';

/// Screen wrapping a [CalendarDatePicker] for selecting the baby's birth date.
/// Returns the chosen [DateTime] via [Navigator.pop], or `null` if cancelled.
class DatePickerScreen extends StatefulWidget {
  const DatePickerScreen({this.initial, super.key});

  final DateTime? initial;

  @override
  State<DatePickerScreen> createState() => _DatePickerScreenState();
}

class _DatePickerScreenState extends State<DatePickerScreen> {
  late DateTime _selected;
  late final DateTime _first;
  late final DateTime _last;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _first = DateTime(now.year - 5, 1, 1);
    _last = DateTime(now.year + 1, 12, 31);
    final initial = widget.initial ?? DateTime(now.year, now.month, now.day);
    _selected = _clamp(initial);
  }

  DateTime _clamp(DateTime d) {
    if (d.isBefore(_first)) return _first;
    if (d.isAfter(_last)) return _last;
    return d;
  }

  void _save() {
    Haptics.tap();
    Navigator.of(context).pop(_selected);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Birth Date')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: CalendarDatePicker(
                initialDate: _selected,
                firstDate: _first,
                lastDate: _last,
                onDateChanged: (d) => setState(() => _selected = d),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
