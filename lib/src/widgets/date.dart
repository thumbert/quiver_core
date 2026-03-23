import 'package:flutter/material.dart';
import 'package:date/date.dart';
import 'package:signals_flutter/signals_flutter.dart';

class DateUi<T> extends StatefulWidget {
  const DateUi({
    required this.model,
    super.key,
    required this.setDate,
    required this.getDate,
    this.allowNull = false,
  });

  final Signal<T> model;

  /// Set the date value inside the model.  Allow null to clear the field.
  final void Function(Date? value) setDate;
  final Date? Function(T model) getDate;
  final bool allowNull;

  @override
  State<DateUi<T>> createState() => _DateUiState<T>();
}

class _DateUiState<T> extends State<DateUi<T>> {
  _DateUiState();

  final controller = TextEditingController();
  final focusNode = FocusNode();
  String? error;

  @override
  void initState() {
    super.initState();
    controller.text = widget.getDate(widget.model.value)?.toString() ?? '';
    focusNode.addListener(() {
      if (!focusNode.hasFocus) {
        /// validate when you lose focus (Tab out of the field)
        setState(() => validate());
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    focusNode.dispose();
    super.dispose();
  }

  void validate() {
    if (controller.text.isEmpty) {
      if (widget.allowNull) {
        widget.setDate(null);
        error = null;
        return;
      } else {
        error = 'Field cannot be empty';
        return;
      }
    }
    try {
      widget.setDate(Date.parse(controller.text));
      controller.text = widget.getDate(widget.model.value).toString();
      error = null; // all good
    } catch (e) {
      error = e.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      focusNode: focusNode,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        errorText: error,
      ),
      controller: controller,
      textInputAction: TextInputAction.done,

      /// validate when Enter is pressed
      onEditingComplete: () {
        setState(() => validate());
      },
    );
  }
}
