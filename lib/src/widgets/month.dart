import 'package:flutter/material.dart';
import 'package:date/date.dart';
import 'package:signals_flutter/signals_flutter.dart';

class MonthUi<T> extends StatefulWidget {
  const MonthUi({
    required this.model,
    super.key,
    required this.setMonth,
    required this.getMonth,
  });

  final Signal<T> model;

  /// Set the month value inside the model
  final void Function(Month value) setMonth;
  final Month? Function(T model) getMonth;

  @override
  State<MonthUi<T>> createState() => _MonthUiState<T>();
}

class _MonthUiState<T> extends State<MonthUi<T>> {
  _MonthUiState();

  final controller = TextEditingController();
  final focusNode = FocusNode();
  String? error;

  @override
  void initState() {
    super.initState();
    controller.text = widget
        .getMonth(widget.model.value)
        .toString()
        .replaceAll('-', ' - ');
    focusNode.addListener(() {
      if (!focusNode.hasFocus) {
        /// validate when you lose focus (Tab out of the field)
        setState(() {
          try {
            widget.setMonth(Month.parse(controller.text));
            controller.text = widget
                .getMonth(widget.model.value)!
                .toIso8601String();
            error = null; // all good
          } catch (e) {
            error = e.toString();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      focusNode: focusNode,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
        errorText: error,
      ),
      controller: controller,

      /// validate when Enter is pressed
      onEditingComplete: () {
        setState(() {
          try {
            widget.setMonth(Month.parse(controller.text));
            controller.text = widget
                .getMonth(widget.model.value)!
                .toIso8601String();
            error = null; // all good
          } catch (e) {
            error = e.toString();
          }
        });
      },
    );
  }
}
